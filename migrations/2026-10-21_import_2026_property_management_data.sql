    -- ==============================================================================
    -- MIGRATION: 2026-10-21_import_2026_property_management_data.sql
    -- HEDEF PROFİL (AGENCY / LANDLORD ID): e4a8d708-acf2-4816-b59a-677c7656ce7c
    -- TANIM: 36 adet mülk, aktif kontratlar, kira ve fatura hareketlerinin aktarımı.
    -- IDEMPOTENT: Tüm kayıtlar deterministic UUID ile üretilmiş olup mükerrer oluşturmaz.
    -- ==============================================================================

    BEGIN;

    -- Ensure contracts.invitee_email allows NULL when tenant email is not provided
    ALTER TABLE public.contracts ALTER COLUMN invitee_email DROP NOT NULL;

    -- ------------------------------------------------------------------------------
    -- 0. CLEANUP PREVIOUS DATA FOR PROFILE e4a8d708-acf2-4816-b59a-677c7656ce7c
    -- ------------------------------------------------------------------------------
    DO $$
    DECLARE
        v_agency_id UUID := 'e4a8d708-acf2-4816-b59a-677c7656ce7c';
    BEGIN
        -- 1. Delete maintenance records linked to properties of this agency
        DELETE FROM public.maintenance_charges 
        WHERE property_id IN (SELECT id FROM public.properties WHERE agency_id = v_agency_id OR landlord_id = v_agency_id);
        
        DELETE FROM public.maintenance_requests 
        WHERE property_id IN (SELECT id FROM public.properties WHERE agency_id = v_agency_id OR landlord_id = v_agency_id);

        -- 2. Delete activity logs
        DELETE FROM public.activity_logs 
        WHERE property_id IN (SELECT id FROM public.properties WHERE agency_id = v_agency_id OR landlord_id = v_agency_id);

        -- 3. Delete rent payments & bills
        DELETE FROM public.rent_payments 
        WHERE property_id IN (SELECT id FROM public.properties WHERE agency_id = v_agency_id OR landlord_id = v_agency_id)
        OR contract_id IN (SELECT id FROM public.contracts WHERE agency_id = v_agency_id);

        -- 4. Delete invitations & leases
        DELETE FROM public.invitations 
        WHERE property_id IN (SELECT id FROM public.properties WHERE agency_id = v_agency_id OR landlord_id = v_agency_id);
        
        DELETE FROM public.leases 
        WHERE property_id IN (SELECT id FROM public.properties WHERE agency_id = v_agency_id OR landlord_id = v_agency_id);

        -- 5. Delete contracts
        DELETE FROM public.contracts 
        WHERE agency_id = v_agency_id 
        OR property_id IN (SELECT id FROM public.properties WHERE agency_id = v_agency_id OR landlord_id = v_agency_id);

        -- 6. Delete properties
        DELETE FROM public.properties 
        WHERE agency_id = v_agency_id OR landlord_id = v_agency_id;
    END $$;

    -- ------------------------------------------------------------------------------
    -- 0.1 UPDATE generate_missing_rent_payments RPC (No Phantom Pre-2026 Debt)
    -- ------------------------------------------------------------------------------
    CREATE OR REPLACE FUNCTION public.generate_missing_rent_payments(p_property_id uuid)
    RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
    DECLARE
    v_contract_id   uuid;
    v_start_date    date;
    v_end_date      date;
    v_current_date  date;
    v_monthly_rent  numeric;
    v_currency      text;
    v_tenant_id     uuid;
    v_due_day       integer;
    v_expenses_cfg  jsonb;
    v_expense       jsonb;
    v_exp_name      text;
    v_exp_amount    numeric;
    v_exp_receiver  text;
    v_approved_row  record;
    BEGIN
    -- Get the ACTIVE contract for the property
    SELECT id, start_date, monthly_rent, currency, tenant_id,
            COALESCE(due_day, 1), COALESCE(expenses_config, '[]'::jsonb)
    INTO v_contract_id, v_start_date, v_monthly_rent, v_currency, v_tenant_id, v_due_day, v_expenses_cfg
    FROM public.contracts
    WHERE property_id = p_property_id AND status = 'active'
    ORDER BY updated_at DESC
    LIMIT 1;

    IF v_contract_id IS NULL OR v_monthly_rent IS NULL THEN
        RETURN;
    END IF;

    -- AUTO-APPROVE: Mark 'declared' as 'paid' after 5 days
    FOR v_approved_row IN
        UPDATE public.rent_payments
        SET status = 'paid', paid_at = (declared_at + interval '5 days')
        WHERE contract_id = v_contract_id
        AND status = 'declared'
        AND receiver_type = 'owner'
        AND declared_at < (now() - interval '5 days')
        RETURNING id, due_date
    LOOP
        INSERT INTO public.activity_logs (property_id, type, metadata)
        VALUES (p_property_id, 'rent_auto_approved',
                jsonb_build_object('month', v_approved_row.due_date));
    END LOOP;

    -- CLEANUP: Remove any pending rows before 2026-01-01
    DELETE FROM public.rent_payments
    WHERE contract_id = v_contract_id
        AND status = 'pending'
        AND (due_date < '2026-01-01'::date OR date_trunc('month', due_date) < date_trunc('month', v_start_date));

    -- Generate rows from start (clamped to 2026-01-01 minimum so pre-2026 contracts never produce 2025 debt)
    IF v_start_date < '2026-01-01'::date THEN
        v_current_date := (date_trunc('month', '2026-01-01'::date) + (v_due_day - 1) * interval '1 day')::date;
    ELSE
        v_current_date := (date_trunc('month', v_start_date) + (v_due_day - 1) * interval '1 day')::date;
    END IF;

    v_end_date := (date_trunc('month', now()) + (v_due_day - 1) * interval '1 day')::date;

    WHILE v_current_date <= v_end_date LOOP
        -- A. Ana kira satırı
        INSERT INTO public.rent_payments
        (property_id, contract_id, tenant_id, amount, currency, due_date, status, title, receiver_type)
        VALUES
        (p_property_id, v_contract_id, v_tenant_id, v_monthly_rent, v_currency, v_current_date, 'pending', 'Kira', 'owner')
        ON CONFLICT (contract_id, due_date, title)
        DO UPDATE SET
        amount    = EXCLUDED.amount,
        currency  = EXCLUDED.currency,
        tenant_id = COALESCE(EXCLUDED.tenant_id, rent_payments.tenant_id)
        WHERE rent_payments.status = 'pending';

        -- B+C. Masraf kalemleri
        IF jsonb_array_length(v_expenses_cfg) > 0 THEN
        FOR v_expense IN SELECT jsonb_array_elements(v_expenses_cfg)
        LOOP
            v_exp_name     := v_expense->>'name';
            v_exp_amount   := COALESCE((v_expense->>'amount')::numeric, 0);
            v_exp_receiver := v_expense->>'receiver';

            IF v_exp_name IS NULL THEN
            CONTINUE;
            END IF;

            IF v_exp_receiver = 'owner' THEN
            INSERT INTO public.rent_payments
                (property_id, contract_id, tenant_id, amount, currency, due_date, status, title, receiver_type)
            VALUES
                (p_property_id, v_contract_id, v_tenant_id, v_exp_amount, v_currency, v_current_date, 'pending', v_exp_name, 'owner')
            ON CONFLICT (contract_id, due_date, title)
            DO UPDATE SET
                amount    = CASE
                            WHEN rent_payments.invoice_url IS NOT NULL THEN rent_payments.amount
                            WHEN rent_payments.amount > 0              THEN rent_payments.amount
                            ELSE EXCLUDED.amount
                            END,
                currency  = EXCLUDED.currency,
                tenant_id = COALESCE(EXCLUDED.tenant_id, rent_payments.tenant_id)
            WHERE rent_payments.status = 'pending';
            END IF;
        END LOOP;
        END IF;

        v_current_date := (v_current_date + interval '1 month')::date;
    END LOOP;
    END;
    $$;

    -- ------------------------------------------------------------------------------
    -- 1. PROPERTIES
    -- ------------------------------------------------------------------------------
    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        '054fc448-a11b-54fc-9f66-f6e913fe84d4', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'ASSERIA STONE PARTNERS', 'BW TERRACES 104', 'BW TERRACES 104', 'ХЕРЦЕГОВАЧКА 16 ГА. 100 /5, Belgrade, Serbia', 'Beograd', 'EUR',
        2500.0, 3700.0, true, '--- Dnevnik Događaja ---
    Zakupac platio 2.850 EUR, 2.300 EUR renta za jul i računi bez struje su bili 470 EUR. Imao pretplatu od 9.160 RSD -> Sonuç: ZAKUPAC NIJE PLATIO STRUJU ZA MAJ, JUN, JUL I AVGUST
    [2025-08-04] Od pretplate u iznosu oD 9.160 RSD odbijeno 4074 RSD za internet, ostalo 5136 RSD
    [2025-08-08] Placen je internet za 104 Terraces za jul 2025 u iznosu 2040 rad + 60 rsd provizija, ukupno 2100 rsd, iskoriscena pretplata koju ima (5136 rsd), tako da pretplata sada iznosi 3036 rsd.
    [2025-08-13] Zakupac obavešten da treba da plati 2.300 EUR rentu za avgust, 51.580,82din računi za jun i 55.247,54 računi za jul (obavešten je da za oba meseca nisu stigli računi za struju) -> Sonuç: Primljeno od zakupca 2.740 EUR, 2.300 renta za avgust i 440 EUR računi za jun
    [2025-08-29] Zakupac obavešten za rentu za septembar 2300 EUR i računi za jul 55.414,52 (475 EUR) bez struje
    [2025-09-17] Jovana poslala račun za EPS za avgust - 15.396,78 din
    [2025-10-02] EPS poslao korigovane račune. Jun - umesto 65.340,74 din iznos od 9.619,57 din. Jul - umesto 75.638,18 din iznos od 11.257,33 din
    [2025-10-10] Ukupno za EPS jun, jul i avgust je 310 EUR, a pretplata koju zakupac ima je 225 EUR -> Sonuç: Treba da doplati 85 EUR za EPS
    [2025-10-20] Zakupac dao novac za rentu i 200 EUR za račune -> Sonuç: Duguje još 370 EUR regularno + još 85 za EPS
    [2025-11-01] depozit zakupca - 4600e: 2300e renta za novembar, 550e racuni septembar, 510e racuni oktobar (ukljucujuci internet),550e racuni novembar (bez interneta),350e dug od avgustovskih racuna,120e ciscenje stana, 85e doplata za struju,ukupni troskovi 4465e, ostaje od depozita 135e
    [2025-11-19] Novi zakupci - Narcis Bečirović i Ana, useljavaju se 20.11.2025. Potpisan Ugovor o zakupu, i zapisnik o primopredaji. -> Sonuç: Prilikom potpisivanja, platili: prvu mesečnu zakupninu u iznosu od 2.500 EUR, kao i depozit u visini od 3.700 EUR.
    [2025-11-20] Zameniće se kreveti u stanu 104 i 207 u BW Terraces tako da će single krevet iz 207 da se prebaci u ostavu a bračni iz 104 u 207.
    [2025-11-24] Stanarka prijavila da joj ne radi mašina za pranje sudova.
    [2025-11-25] Angažovan majstor iz Bosch-a da popravi mašinu za sudove, mašina je popravljena. -> Sonuç: Popravka mašine plaćena 6.000 dinara
    [2025-12-03] Izneto iz stana: TV iz dnevne sobe, mikrotalasna i dve zlate stone lampe i preneto u stan 207
    [2025-11-27] Zakupac trazio dubinsko pranje duseka u master sobi -> Sonuç: Poslato je dubinsko, platila je sama 3000 rsd, odbiti im od kirije
    [2025-11-30] Tražila je da se kupi naddušek za master sobu -> Sonuç: Kupila je sama u Yisku i tražila je da joj se odbije od kirije 21.700 rsd
    [2025-12-19] Platila 2290 eura za period 20.12. do 19.01. Odbijeno joj je 210 eura za naddušek i dubinsko čišćenje dušeka. Za 11 dana novembra dala 200 eura za račune
    [2026-01-20] Platila 2.500 EUR rentu za period od 20.01. - 19.02.2026. + 650 eur za racune za decembar
    [2026-02-20] Platila 2.500 EUR rentu za period od 20.02. - 19.03.2026. + 705 eur za racune za januar
    [2026-03-20] Platila 2.500 EUR rentu za period od 20.03. - 19.04.2026. + 655 EUR za racune za februar
    [2026-04-21] Platila 2.500 EUR rentu za period od 20.4. - 19.05.2026. + 600 EUR + 1000 din za racune za mart
    [2026-04-21] Nataša je donela Ani usisivac iz stana C 7.28 jer se usisivac iz stana 104 pokvario, pokvaren usisivac je kod Natase u gepeku
    [2026-05-20] Platila 2.500 eur rentu za period od 20.05. - 19.06.2026. + 69.000 dinara za racune za april
    [2026-06-20] Platila 2.500 eur rentu za period od 20.06. - 19.07.2026. + 600 eur za racune za maj -> Sonuç: Pretplata 35 eur za naredni mesec
    [2026-07-20] Platila 2.500 eur rentu za period od 20.07. - 19.08.2026. + 500 eur i 600 din za racune za jun -> Sonuç: Dala je manje 35 eur koliko je ostala pretplata
    [2026-08-06] Krevet iz spavace sobe iz 104 Terraces prebacen u 2104 u Rivieru
    [2026-08-20] Platila 2.500 eur rentu za period od 20.08.-19.09.2026. + 350 eur za racune -> Sonuç: Ukupni racuni su 64.222,34 dinara, odbijeno 24.000 za komarnike
    [2026-09-17] Platila 2.500 eur rentu za period od 20.09.-19.10.2026. + 550 eur i 1.300 din za racune
    [2026-09-23] Sto i stolica  iz master spavace sobe prebacen u stan 2203 u Rivieru, dok je nocni stocic prebacen u 2401 Perla, a drugi nocni stocic je u stanu 207
    [2026-02 Notu]: 20.02.-19.03
    [2026-03 Notu]: 20.03.-19.04.
    [2026-04 Notu]: 20.04.-19.05.
    [2026-05 Notu]: 20.05.-19.06.
    [2026-06 Notu]: 20.06.-19.07.
    [2026-07 Notu]: 20.07.-19.08.
    [2026-08 Notu]: 20.08.-19.09.
    [2026-09 Notu]: 20.09.-19.10.', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Parking", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        '4a1858ac-cd89-5ded-a31b-67561b05923f', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'ASSERIA STONE PARTNERS DOO', 'BW TERRACES 207', 'BW TERRACES 207', 'ХЕРЦЕГОВАЧКА 16 ГА. 55 /5, Belgrade, Serbia', 'Beograd', 'EUR',
        2500.0, 5000.0, true, '--- Dnevnik Događaja ---
    [2025-10-08] Računi za avgust 51.747,47 i da nedostaje račun za struju (obavešten u poruci)
    [2025-11-04] Tepisi iz dnevne sobe bili na dubinskom pranju -> Sonuç: Vraćeni u stan 04.11.
    [2025-11-05] Gledanje stana sa Vojinom iz agencije Brick pro u 10h
    [2025-11-06] Od depozita zakupca Jovana Avram, odbijeno je: 64.026,97 rsd za račune za septembar i 63.715,06 rsd za račune za oktobar, a ostatak u iznosu 1658 EUR iskorišćeno za deo rente za novembar
    [2025-12-02] NOVI ZAKUPAC - uselio se u stan Kostiantyn Kuzmenko -> Sonuç: Data prva renta u iznosu od 2.500 EUR i dva depozita 2.500 EUR x 2 = 5.000 EUR
    [2025-12-03] Potrebno je premestiti bracni krevet iz prve spavace (koji je tu stavljen iz prve spavace stana 104) u master sobu a sivi kozni krevet izbaciti iz stana i odneti u magacin u Sremcicu. Televizor, mikrotalasna i dve zlatne lampe iz stana 104 preneto u stan 207. Potrebno je kupiti nogice za tv koji je donet iz 104 i montirati tv u master spavacu na komodu -> Sonuç: Sivi krevet iz master sobe je ipak ostao u stanu a atlas krevet koji je iz stana 104 donet u gostinsku sobu prenet je u magacin u Banovce kod Nikole Korde. Takodje je iznet i radni sto i stolica u isti magacin. Nocni stocic i dve zlatne lampe iz stana 104 ostali su u gostinjskoj sobi stana 207
    [2026-03-10] Preuzeta kirija za mart u iznosu od 2500 EUR i novac za racune za januar u iznosu od 530e -> Sonuç: Zakupac je dao 3000 EUR i 5000 din, u pretplati je 1490 din
    [2026-03-26] Struja nije ocitana za februar, stavljen iznos kao i za prosli mesec
    [2026-04-01] Poslata poruka za placanje rente za april i racuna za februar
    [2026-04-06] Placena renta za april i racuni za februar -> Sonuç: 3100e dao, ima pretplatu iz prethodnog perioda
    [2026-04-29] Struja je stigla 33.337,37, obzirom da za februar struja nije ocitana, mi smo naplatili 8.805.30 kao za januar, tako da cemo od ovog iznosa oduzeti tih 8 hiljada i dodati osnovicu od 2.290,73 dinara -> Sonuç: Naplata za mart ce biti 26.822,80
    [2026-05-06] Placena renta za maj i racuni za februar -> Sonuç: 380.000 dinara dao, 1993,26 dinara pretplata
    [2026-06-02] Zakupac kontaktiran u vezi placanja rente za jun i racuna za april, ali nije u zemlji pa je rekao 9-10 juna da ce biti tu
    [2026-06-09] Preuzeta kirija za jun u iznosu od 2500 EUR i novac za racune za april u iznosu od 550e -> Sonuç: Pretplata 2.880 dinara
    [2026-07-09] Pruzeta kirija za jul + novac za racune za maj -> Sonuç: 355.000 dinara + 1500 din uzeto iz pretplate
    [2026-08-05] Preuzeta kirija za avgust + novac za racune za jun -> Sonuç: 2.500 eur renta + 500 eur i dve hilj za racune
    [2026-09-08] Preuzeta kirija za septembar + novac za racune za jul -> Sonuç: 2.500 eur renta + 600 eur za racune, ostaje pretplata 43 eur
    [2026-10-13] Preuzeta kirija za oktobar + novac za racune za avgust -> Sonuç: 2.500 eur renta + 520 eur racuni za avgust + pretplata', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Parking", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'GROWTH EDGE DOO BEOGRAD', 'BW SIMFONIA 1501', 'BW SIMFONIA 1501', 'ХЕРЦЕГОВАЧКА 15 ГА. 59 /1, Belgrade, Serbia', 'Beograd', 'EUR',
        3600.0, 7200.0, true, '--- Dnevnik Događaja ---
    [2025-11-04] Miroslav je tražio daljinski i tražio je da se stakleni sto iznese iz njegovog stana -> Sonuç: Daljinski uzet iz stana 0901 West i biće mu odnešen
    Miroslav platio rentu za januar i račune za novembar
    [2026-02-11] Novi problem u stanu 1501, BW Simfonija. U pitanju je curenje vode, ovoga puta iz kupatila (ne sa terase).
    Komšinica iz stana 1401 me je obavestila da joj voda curi iz plafona u spavaćoj sobi i kaplje direktno na krevet.
    Odmah smo kontaktirali izvodjaca radova - Milenium tim. Obavešteni smo da zgrada više nije u garanciji, ali da će nam izaći u susret i izvršiti pregled. Nakon ulaska u stan i provere, utvrđeno je da voda zaista prodire iz našeg kupatila u stan ispod.
    Danas sam dobila poziv od Milenium tima sa pitanjem kada mogu da započnu radove u kupatilu. -> Sonuç: Zakupac je bio izrazito nezadovoljan zbog ponovnog uznemiravanja, a nakon informacije da će biti neophodna sanacija kupatila, izjavio je da namerava da napusti stan.
    [2026-02-23] Smanjena renta sa 3600e na 3200e -> Sonuç: Zbog nekoriscenja drugog kupatila zakupcu je smanjena renta
    Poslata mu je poruka u vezi placanja rente za mart, dana 09.03.
    Uraditi Aneks ugovora sa smanjenom rentom
    [2026-03-10] Preuzeta kirija od zakupca 3200 EUR
    [2026-04-01] Poslata poruka u vezi placanja rente i racuna za februar, takodje smo ga pitali da li zeli da produzi ugovor, obzirom da mu istice u aprilu -> Sonuç: Rekao je da zeli da produzi na 6 meseci, u cetvrtak 09.04. je dogovor da potpise
    [2026-04-09] Miroslav je dao 3.150 evra, i nije dao novac za racune, rekao je da ce dati u toku sledece nedelje, jer nije imao novac u kesu, tada ce dodati i 50e za kiriju
    [2026-04-25] Miroslav dao 4010 EUR za rentu za maj, i racune za februar -> Sonuç: 3200e renta za maj + 50e dug od rente za april + 760e racuni za februar
    [2026-05-04] Stavljena struja iznos kao za februar, posto nije za mart stigla
    [2026-05-19] Pokupljen novac za racune za mart 650 EUR -> Sonuç: Duguje 18 eur ukupno ( 7 eur za mart, za novembar 6e i za oktobar 5 e)
    [2026-06-05] Zakupac je kontaktiran u vezi placanje rente i racuna, nije u zemlji i bice tek oko 20-og
    [2026-06-26] Placena renta za jun i jul u iznosu od 6.400 eur + za racune za april i maj  dao 1260 eur -> Sonuç: Struja jos uvek nije stigla tako da sam mu uzela iznos kao i za prosli mesec
    [2026-07-28] Placena renta za avgust 3.200 eur + za racuni za jun 620 eur -> Sonuç: Struja stigla, tako da je doplatio i tu razliku od 2.000 din
    [2026-09-16] Placena renta za septembar 3.200 eur + za racuni za jul 670 eur
    [2026-10-16] Placena renta za oktobar 3.200 eur + za racuni za avgust 600 eur', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Parking (Kalan)", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity (Kalan)", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance (Kalan)", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Parking", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Infostan (Kalan)", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        '2b57ad41-50e0-578e-a0c8-c281e7391e3a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'GROWTH EDGE DOO BEOGRAD', 'BW SOLE 1401', 'BW SOLE 1401', 'БУЛЕВАР ВУДРОА ВИЛСОНА 21 ГА. 34 /1, Belgrade, Serbia', 'Beograd', 'EUR',
        3000.0, 6000.0, true, '[Orijinal Kontrat Bitişi: 2025-07-31]
    --- Dnevnik Događaja ---
    [2026-02-18] Prijavljen problem na terasi stana - došlo je do odvajanja dela plafona terase – ukrasne obloge / fasadnog elementa (gipsane ili slične završne obrade), koji trenutno visi i postoji realna opasnost da padne.
    Prema onome što je vidljivo sa terase, deluje da dolazi do podlivanja vode sa terase stana iznad, usled čega se materijal na plafonu naše terase natapa i odlepljuje.
    Uraditi aneks ugovora
    [2026-03-18] Stigao je račun za struju u iznosu od 88.371,78 za ceo prethodni period za koji su zakupci u stanu
    [2026-04-02] Jovana mailom potvrdila da je placena renta za mart 27.03.2026.
    [2026-04-17] Jovana mailom potvrdila da je placena renta za april 16.04.2026.
    [2026-04-21] Jovana mailom potvrdila da su placeni racuni za januar i februar
    [2026-04-30] Jovana mailom potvrdila da su placeni racuni za decembar 2025. -> Sonuç: Uplacen iznos od 60.858,37
    [2026-05-14] Jovana mailom potrvdila da je placena renta za maj 2026 -> Sonuç: 3.000 eur
    [2026-07-30] Jovana mailom potvrdila da je placena renta za jun 2026
    [2026-08-24] Jovana mailom potvrdila da je placena renta za avgust 2026
    [2026-09-03] Jovana mailom potvrdila da su placeni racuni za mart, april i maj', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "bank_transfer"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "bank_transfer"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "bank_transfer"}, {"name": "Parking", "receiver": "owner", "amount": 0.0, "payment_method": "bank_transfer"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        'd2cd1c46-4fac-5919-a741-93f34e980743', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'GROWTH EDGE', 'BW RESIDENCES 402', 'BW RESIDENCES 402', 'ХЕРЦЕГОВАЧКА 14Б СТ. 402, Belgrade, Serbia', 'Beograd', 'EUR',
        1800.0, 2700.0, true, '--- Dnevnik Događaja ---
    Obavesten 01.03., rekao da je na putu. Obavesten opet o iznosu za placanje, kirija mart i racuni za januar dana 09.03.
    [2026-03-19] Pokupljena kirija za mart 1800e plus 350e za racune -> Sonuç: pretplata 3000 dinara za racune
    [2026-04-01] Obavesten o placanju rente za april i racuna za februar, rekao da se nadjemo u ponedeljak
    [2026-04-06] Dao rentu za april 1800e plus racune za februar 39.000 -> Sonuç: u pretplati  3000 od prosli put
    [2026-04-29] Racun za struju nije stigao za mart, tako da je stavljena ista cifra kao i za februar
    [2026-05-08] Placena renta za maj i racuni za mart -> Sonuç: 1800 eur + 37.000 dinara za racune
    [2025-05-15] Usao je novi zakupac Borko - Obzirom na to da je Nikola platio rentu za ceo mesec, vraticemo mu razliku kada budu dospeli i racuni -> Sonuç: Placen je depozit 2.700 eur + prva renta 1800 eur
    [2025-05-28] Nikoli vracen depozit u visini jedne mesecne rente i razlika za maj obzirom da je ranije izasao iz stana a platio je ceo mesec -> Sonuç: 1.800 eur za depozit + 1045 eur za razliku
    [2026-06-03] Od Borka pokupljena renta u iznosu od 1050 eur za jun -> Sonuç: uzeto 300 eur za aprilske racune od 900 eur koji su ostali od Nikole da pokriju troskove
    [2026-07-01] Pokupljena kirija za jul 1800e + 13.400 dinara za racune za period od 13.05.-31.05
    [2026-07-31] Pokupljena kirija za avgust 1.800 eur + novac za racune za jun + deo info stana za maj za period od 14.05.-31.05. -> Sonuç: Ukupno 40.000 dinara
    [2026-08-03] Jovani dato 100 eur + 2000 din iz gladoviceve koverte za racune za maj od 01.05.-13.05.
    [2026-09-01] Placena renta za septembar 1800 eur + 32.200 din za racune za jul
    [2026-09-29] Bojler u stanu crkao, pozvan servis, odnosno morace novi bojler, jos uvek se ne zna cena
    [2026-10-01] Placena renta za oktobar (1.800 eur) kao i racuni za avgust 32.100 dinara
    Popravljen bojler u stanu, popravka je iznosila 16.900 dinara
    [2026-05 Notu]: novi zakupac platio racune za period od 13.05-31.05', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Parking", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        '3202a566-41ba-594d-8870-f5f37147e9a0', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'МИМИЋ АЛЕКСАНДАР', 'BW AQUA 1607', 'BW AQUA 1607', 'ХЕРЦЕГОВАЧКА 23 СТ. 1607, Belgrade, Serbia', 'Beograd', 'EUR',
        2450.0, 3450.0, true, '--- Dnevnik Događaja ---
    [2025-10-03] 2900e - renta za oktobar 2600e + racuni za avgust 300e (racuni su 38.661,26 + provizija 441.03 = ukupno 39.102,29 / 334e - pretplata 45e = 289e -> Sonuç: zakupac sada ima novu pretplatu 11e
    [2025-11-24] Popravljena balkonska vrata iz dnevne sobe i popravljena balkonska vrata iz master spavaće sobe -> Sonuç: Plaćeno sve 100 EUR
    [2025-11-25] Bila Boba da skine zavese, pa su iz perionice veša došli i pokupili zavese. Takođe, Nataša odnela sedalni deo ugaone garniture u Zemun na ušivanje, jer se rašila. -> Sonuç: Uslugu skidanja i nameštanja zavesa Bobi plaćamo 4.000 dinara, a pranje zavesa 34.970 dinara.
    [2025-11-26] Depozit od Gizem u iznosu od 3.900 EUR: - 2.600 EUR zakupnina za novembar, 350 EUR troškovi za septembar, 350 EUR troškovi za oktobar, 380 EUR troškovi za novembar -> Sonuç: Nakon svih ovih odbitaka, preostali iznos je 220 EUR koji je refundiran
    [2025-12-01] Pranje sofe plaćeno 4.000 dinara, ušivanje sedišta sofe plaćeno 3.000 dinara i dato čistačicama (2 čistačice po 8h) 16.000 dinara
    [2025-12-02] I mesečna kirija - 01.12 - 31.12. 2025. -> Sonuç: 2.450 EUR (1.900 EUR + 64.350 RSD)
    [2025-12-15] Računi za novembar plaćeni iz depozita od Gizem -> Sonuç: Naplatićemo i Nikolaju 10 dana računa za novembar
    [2026-01-21] Nikolaj platio račune za decembar - 55.200 dinara -> Sonuç: PREBACITI U NOVU TABELU
    [2026-02-04] Nikolaj dao kiriju za februar 2.450 eura -> Sonuç: PREBACITI U NOVU TABELU
    [2026-03-03] Placena kirija 2.450 eura za mart i racuni za januar -> Sonuç: 2.450 eur + 59.480 rsd
    [2026-04-02] Placena kirija 2.450 eura za april i racuni za februar -> Sonuç: 2.450 eur + 62.500 rsd
    [2026-04-28] Placena kirija 2.450 eur za maj i racuni za mart -> Sonuç: 2.450 eur + 57.660 rsd
    [2026-06-03] Placena kirija 2.450 eur za jun i racuni za april -> Sonuç: 2.450 eur + 52.860 rsd
    [2026-07-01] Placena kirija 2.450 eur za jul i racuni za maj -> Sonuç: 2.450 eur + 54.350 rsd
    [2026-08-05] Placena kirija 2.450 eur za avgust i racuni za jun -> Sonuç: 2450 eur + 51.640 rsd
    [2026-09-08] Placena kirija 2.450 eur za septembar i racuni za jul -> Sonuç: 2450 eur + 52.100 rsd
    [2026-10-01] Placena kirija 2.450 eur za oktobar i racuni za avgust -> Sonuç: 2450 eur + 58.810 rsd', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Parking", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'МИМИЋ АЛЕКСАНДАР', 'BW AQUA 1807', 'BW AQUA 1807', 'ХЕРЦЕГОВАЧКА 23 ГА. 418 /2, Belgrade, Serbia', 'Beograd', 'EUR',
        2600.0, 5200.0, true, 'Kontrat Notu: Orijinal Kontrat: 2023-11-06 - 2026-11-05.
    --- Dnevnik Događaja ---
    [2025-04-30] Zakupac se zalio na prljave prozore iako su bili alpinisti da ih ociste i trazio da se resi problem. -> Sonuç: Pronašla sam profesionalne čistače prozora koji poseduju adekvatnu opremu za čišćenje unutrašnjih površina. Radi se o ruskoj agenciji specijalizovanoj za usluge čišćenja.
    [0205-06-04] Zakupac je imao problema sa klimom. -> Sonuç: Organizovali smo ovlasceni servis klima uredjaja.
    [2025-10-06] Pokupljena kirija od zakupca Ivana, nije više 2600 eur nego 2500 eur
    [2025-12-05] Pokupljena kirija od zakupca
    [2025-01-08] Zakupac se više puta obratio zbog nečistoće u zgradi, prljavih spoljnih prozora i kvara ulaznih vrata zgrade -> Sonuç: Pozvan upravnik zgrade više puta i poslato više mejlova sa zahtevom zakupca
    [2026-03-04] Pokupljena kirija od zakupca 2500e
    [2026-04-02] Obavesten za placanje rente za april
    [2026-04-06] Placena renta za april 2.500e
    [2026-05-04] Placena renta za maj 2.500e
    [2026-05-12] Ivan nas je kontaktirao da opet ne radi klima, obzirom da se javlja isti problem posle manje od godinu dana, kontaktirale smo upravnika, ali smo dobile odgovor da ne moze nista da uradi. Obzirom da je bio petak, nismo mogli da pronadjemo majstora, a on je hteo odmah da se resi pa je sam organizovao majstore. Popravka je iznosila 530 eur, s tim sto je Ivan rekao da ce dati 200 eur. Sve slike i izvestaj se nalaze u folderu popravki.
    [2026-06-03] Sa zakupcem postignut dogovor da ce se troskovi za popravku klime koja je iznosila 530 eur podeliti na pola, tako da je polovina odbijena od rente -> Sonuç: Zakupac je platio rentu u iznosu od 2.232,5 eur
    [2026-07-02] Placena renta za jul  2.500 eur
    [2026-08-06] Placena renta za avgust 2.500 eur
    [2026-09-01] Placena renta za septembar 2.500 eur
    [2026-10-02] Placena renta za oktobar 2.500 eur', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Parking", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        '795db987-07d2-515b-84cd-1656f271953d', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'GROWTH EDGE DOO', 'WEST 9.1', 'WEST 9.1', 'ОМЛАДИНСКИХ БРИГАДА 86 СТ. 9.1, Belgrade, Serbia', 'Beograd', 'EUR',
        1650.0, 1650.0, true, '--- Dnevnik Događaja ---
    [2025-10-02] Za 9.1 West kulu nam je ostao jedan ceo depozit od bivseg stanara I od tog iznosa treba da odbijemo 60 eur za ciscenje i odbicemo mu sve dane u oktobru dok je stan prazan, taj presek cemo uraditi na kraju meseca jer ne znam od kog datuma cemo izdati stan (nemamo jos uvek nove stanare) -> Sonuç: 01.10.2025 Zakupcu je od depozita u iznosu od 1800 eur odbijeno 840 eur za racune za jul, avgust i septembar, vraceno mu je 960 eur. Jos jedan depozit u iznosu od 1800 eur ostao je kod nas
    9.1 Julski racuni u iznosu od 36.186 rsd naplaceno od depozita
    9.1 Nisu stigli svi racuni za avgust (Form focus) zakupcu izracunato prosecno 36.000 i naplacano od depozita
    9.1 Nisu stigli svi racuni za septembar (Form focus) zakupcu izracunato prosecno 36.000 i naplacano od depozita
    Imao pretplatu 84 eur, (bila je 105 eur, ali je odbijeno za karticu 21 eur)
    Renta za oktobar odbijena zakupcu od depozita, a računi za oktobar su išli na teret vlasnika. U toku oktobra meseca u stanu je boravio Luka advokat
    Proveriti da li je Jovana fakturisala rentu za decembar i račune za novembar novom zakupcu Eko Srbija
    [2026-04-02] Jovana mailom potvrdila da je placena renta za mart 27.03.2026.
    [2026-04-17] Jovana mailom potvrdila da je placena renta za april 15.04.2026. kao i da su uplatili prefakturisane troskove za:
    decembar 2025 - 44.490,27 rsd
    januar 2026 - 47.727,03 rsd
    [2026-05-14] Jovana mailom potvrdila rentu za maj da je placena i racuni za februar
    [2026-06-17] Jovana mailom potvrdila da je placena renta za jun, kao i racuni za mart i april
    [2026-07-30] Jovana mailom potvrdila da je placena renta za jul
    [2026-08-04] Jovana mailom potvrdila da je placena renta za avgust
    [2026-09-07] Jovana mailom potvrdila da je placena renta za sept', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Internet/TV", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Parking", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        '992ab199-2589-5896-816a-963caadd041e', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'GROWTH EDGE DOO', 'WEST 18.1', 'WEST 18.1', 'ОМЛАДИНСКИХ БРИГАДА 86/2 ГА. Т1-046, Belgrade, Serbia', 'Beograd', 'EUR',
        2000.0, 2000.0, true, 'Kontrat Notu: Orijinal Kontrat: 2024-04-08 - 2027-03-31.
    --- Dnevnik Događaja ---
    [2025-08-12] Od iznosa 39.750 koji su zakupci bili duzni da plate za komunalije za jun, odbijen je iznos od 10.500 za Ikea policu u vesernici, tako da je placeno 250 eur
    [2025-08-12] Od iznosa od 150 eur koje je preuzeto od zakupca placeno Jovici stolaru, izrada i ugradnja ogledala u hodniku u iznosu od 150 eur, za isplatu Jovani 100 eur
    [2025-08-15] Prilikom ugradnje ogledala je pomeren prekidac za svetlo i sad im ne radi svetlo u hodniku
    [2025-08-15] Treba da se kupi i ugradi daljinsko zvonce. Sitno curenje u lavabou,popustio silikon. Zamena cevi aspiratora. Aluminijumsko fleksibilno crevo treba da se zameni. Aspirator je na filter i nema uzlaz u ventilaciju. Zele da im se zameni crevo jer se oseca. Makaze na prozoru u spavacoj sobi onemogucavaju da se zatvori. -> Sonuç: Kupio je i ugradio i popravio je svetlo u hodniku usled toga sto je skinuto ogledalo i zalepljeno
    [2025-08-15] Dodatne police u garderoberu. -> Sonuç: Ugradnja polica
    [2025-10-27] Zakupac predao iznos od 1000 eur za racune za avgust i septembar, ima pretplatu 20 eur. Za klimatizaciju naplacen iznos za avgust 21.000rsd umest 10.430 rsd -> Sonuç: Ima dug za avgust i septembar 82,58 eura
    [2025-12-25] Zakupac predao iznos od 900 eura za račune za oktobar i novembar -> Sonuç: Duguje još 23 eura. Ukupan dug za avgust-novembar je 105 eura, dogvoreno da se to odbije za stolice koje će oni kupiti
    [2026-02-24] Zakupac je predao iznos od 520e, za racune za decembar i dug od 83+23e
    [2026-03-09] PROVERENO JOS JEDNOM SA Jovanom, renta je placena do 31.03.2026. Poslati im upit do kada ostaju u stanu i obavestiti ih o placanju
    [2026-03-11] Ksenija platila račune za januar 350 EUR -> Sonuç: DUGUJE JOŠ 17 EURA
    [2026-03-30] Poslata oba aneksa, kao i  iznos za rentu i račune koji trebaju da plate
    [2026-04-01] Poslata poruka kada im odgovara, rekla je Ksenija da ce za vikend pogledati anekse
    [2026-04-02] Ksenija slikala račun koji je domar dao zbog zamene gumice ispod sudopere, i trazila majstora za vrata od kupatila
    [2026-04-09] Ksenija bila u kancu, donela potpisane anekse, 2000e + 400e za racune
    [2026-04-21] Pozvano je više majstora za vrata od kupatila, zabrali smo najpovoljniju opciju, dogovor je da se odradi račun na firmu i da se popravka odradi danas
    [2026-04-23] Prethodni majstor koji je trebao da nam popravi bravu je otkazao, tako da smo pozvali drugog, otisao je i zamenio bravu -> Sonuç: 8000 dinara zamena i popravka brave, racun na firmu
    [2026-04-29] Struja za mart nije stigla, stavljen iznos kao za februar
    [2026-05-05] Placeni racuni za mart i renta za maj -> Sonuç: 2000eur za rentu + 400 eur za racune
    [2026-05-07] Struja za mart je stigla, promenjen je iznos u tabeli, duguje 600 dinara, naplatiti sledeceg meseca to dugovanje
    [2026-06-02] Placena renta za jun 2000 eur + racuni za april 450 eur -> Sonuç: Dala 600 din dug za struju, ostaje joj 20e za sledeci mesec pretplate
    [2026-07-06] Placena renta za jul 2000 eur + racuni za maj 380 eur ( obzirom da ima pretplatu 20e racuni su 360) -> Sonuç: Ksenija dala 400 eur za racune umesto 360, ostaje 40 eur za sledeci mesec
    [2026-08-11] Placena renta za avgust 2000 eur + racuni za maj 350 eur -> Sonuç: Ksenija dala 350 eur jer je imala pretplatu 40 eur
    [2026-09-10] Placena renta za septembar 2000 eur + racuni za jul 442 eur -> Sonuç: Jovani dato 490 eur za racune, bio je dug od 40 eur
    [2026-10-13] Placena renta za oktobar 2000 eur + racuni za avgust 500 eur + 2000 din', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Parking", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'ASSERIA STONE PARTNERS DOO', 'A BLOK', 'A BLOK', 'УРОША МАРТИНОВИЋА 3 ГА. 204, Belgrade, Serbia', 'Beograd', 'EUR',
        2500.0, 2500.0, true, '--- Dnevnik Događaja ---
    [2025-05-27] Stanarka je pre par dana prijavila da joj ne radi usisivac,takodje i da joj ne radi prekidač za bojler -> Sonuç: Angažovali smo električara i kvar u vezi sa napajanjem električne energije i prekidačem je uspešno otklonjen. Usisivač je odnet na servis i popravljen je.
    [2025-10-20] Margarita prethodni zakupac, ostavila je avanso iznos za racune za septembar 2025 koji u tom trenutnu jos nisu dospeli, avans je iznosio 23.100 rsd a racuni su dosli u iznosu od 24.096 -> Sonuç: Internet sbb proveriti da li je placen za septembar
    [2025-09-24] Prilikom obilaska stana nakon izlaska zakupca lavabo u jednom od kupatila bio je naprso, a sada ta pukotina deluje jos gore, pored toga, ormaric lavaboa je potpuno raskliman I truo od vode - Potrebno je zameniti i lavabo i ormaric lavaboa (pronasla sam u Ikei komplet za 43.000 rsd, i pretpostavljam da su ruke jos oko 100 eur)
    Police u singl decijoj sobi su potpuno rasklimane, I kada se nesto stavi na njih, krive se i deluju da ce da padnu i to bi trebao neko da pricvrsti sa dodatnim drzacima -> Sonuç: (cena novog TV/a 70.000 rsd plus nosac 8000 rsd, plus ruke vrvt oko 50 eur)
    [2025-10-02] Od zakupca je juce primljen iznos od 2500 eur za rentu za oktobar. -> Sonuç: Jovana bi trebala da preda iznos od 130 eur za usluge majstora koji je dopremio iz Lesnine i zamenio lavabo i ormaric u kupatilu, zalepio lajsnu na tv zidu u dnevnoj sobi, izneo sa terase velike saksije sa zemljom, i pricvrstio police u sobi. - placeno
    Kupljena su 4 nova jastučeta za garnituru u dnevnoj sobi
    [2025-12-05] Primljen iznos od 2500 za rentu i 22.000 za racune za oktobar
    [2026-02-11] Stanar prijavio da mu ne radi prekidač za bojler i prekidač za svetlo u jednom kupatilu. Takođe je prijavio da mu ne radi smart sistem na televizoru ni wi-fi u spavaćoj sobi -> Sonuç: Mora da se angažuje električar
    [2026-03-06] Primljen iznos od 292.500 rsd za rentu za mart
    [2026-03-20] Primljen iznos od 83.500 rsd za racune za januar i februar -> Sonuç: 7.200 dinara za mts uzeto, zamolio je da platimo
    [2026-04-02] Poslata poruka za kiriju za april
    [2026-04-06] Placena kirija za april -> Sonuç: 292.500 primljeno
    [2026-04-24] Elektricar je bio juce, promenio je prekidac, ustanovio je da bojler ne radi, a internet na tv-u ce popraviti -> Sonuç: Danas ce otici majstor za bojler da ga popravi, cena iznosi 12.000 dinara, Darko ce platiti pa cemo mu odbiti taj iznos kada bude davao za troskove
    [2026-05-04] Pavle elektricar popravio prekidač, svetlo (u kupatilu) i resio problem sa TV-om u spavaćoj sobi (sproveo Lan kabal do TV-a) pa sad imaju internet -> Sonuç: Iznos popravki je iznosio 8.000 dinara
    [2026-05-06] Primljen iznos od 314.300 dinara, renta za maj i racuni za mart -> Sonuç: Obzirom da je platio sam popravku za bojler naplaceno mu je 12 hiljada manje
    [2026-06-19] Prekidac ne radi na kupatilu ponovo, pozvan elektricar otici ce u ponedeljak da popravi
    [2026-06-22] Popravljen prekidac, popravka je iznosila 6.800 dinara, uplaticemo Pavlu na racun, pa ce Jovana da nam da novac
    [2026-07-07] Pokupljena renta za jul 2.500 eur + racuni za maj -> Sonuç: Ukupno 323.800 dinara uzeto
    [2026-08-04] Pokupljena renta za avgust 2.500 eur + racuni za jun -> Sonuç: Ukupno 292.500 din za rentu i 24.700 din za racune
    [2026-08-18] Krevet iz A bloka prebacen u ostavu 081 i 088 u Rivieru -> Sonuç: Odnesena i nova garnitura za terasu i postavljena, ti troskovi su iznosili 200 eur za prenos iz emecete u stan bastenski namestaj, nakon toga kreveti iz a bloka u rivieru, bastenski set i jastuci su iznosili 29.680 dinara
    [2026-09-08] Pokupljena renta za septembar + racuni za jul -> Sonuç: 320.000 dinara
    [2026-10-14] Pokupljena renta za oktobar + racuni za avgust', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Parking", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        '6308167e-af32-53bb-9c22-df5efa478fa1', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'ASSERIA STONE PARTNERS', 'C 7.28 LANDMARK', 'C 7.28 LANDMARK', 'БУЛЕВАР КРАЉА АЛЕКСАНДРА 142 ГА. 51 /5, Belgrade, Serbia', 'Beograd', 'EUR',
        2000.0, 2400.0, true, '--- Dnevnik Događaja ---
    [2025-06-23] Zakljucen ugovor o zakupu. Uplaceno: depozit 2300 eur i prva zakupnina 2300
    [2025-08-04] Zakupac prijavio da ne radi usisivac. -> Sonuç: Uzet usisivac iz A 5.17 i odnet u C 7.28, a pokvareni usisivac kod Natase u gepeku, treba da se nosi na servis
    [2025-08-04] Zakupac istakao zahtev da zeli draperije u obe spavace sobe -> Sonuç: Biljana odobrila, narucene su draperije kod Gabrijele dana 06.08
    [2025-08-05] Zakupac obavesten da treba da plati 64 eur za komunalije za deo juna
    [2025-09-25] Zakupac trazio instalaciju i kupovinu TV za spavacu sobu
    [2025-10-02] Poručen novi televizor - 44.000 din + 2.000 din dostava
    [2025-10-20] Namontiran TV, Radmila sama kupila nosač, cena montaže 4.500 dinara -> Sonuç: Nije trazila refundaciju za nosac za TV
    [2025-10-27] Jovana potvrdila: 2300 eur renta do 22.11 (novembar) + 36500 rsd za racune za septembar (racuni su 34.490,11 rsd) imala dug od 25 eur, sada duguje jos 915 rsd.
    [2025-11-25] Platili rentu za decembar - 2.300 EUR i dali 300 EUR za račune za oktobar -> Sonuç: Dali još 1000 dinara za dug iz prethodnog meseca
    Otkazali ugovor o zakupu. Iz depozita odbijeno za račune za novembar i decembar, za čišćenje stana 150 eura sanacija parketa 100 eura i renta za januar 2300 eura
    [2026-02-11] Stanarka prijavila curenje bojlera. Takođe je prijavila da joj ne radi mali bojler i da je u pitanju utičnica. -> Sonuç: Curenje je sanirano, pozvali smo izvođača radova jer je zgrada i dalje u garanciji. Za bojler je angažovan izvođač koji će ovih dana to da reši.
    Stanarka je izbacila i predala Natasi, sve jastuke, jorgane i svu posteljinu iz stana, i to ce biti smesteno u ostavu stana 1607 BW Aqua u plavim Ikea torbama. Takodje je izbacila usisivac, ali ga nije predala nama, potrebno je da ga ona vrati prilikom isteka ugovora.
    [2026-03-25] Stanarka je obavestena o iznosu koji treba da isplati za racune za februar
    [2026-03-30] Sara je rekla da će danas ili sutra da ostavi novac za račune
    [2026-04-01] Preuzet iznos za racune za februar 500 EUR + 2.000 RSD
    [2026-04-21] Nataša je uzela usisivač od Sare jer ga ona ne koristi, pa je odnela Ani u Terraces 104 jer se njen pokvario
    [2026-05-06] Preuzet iznos za racune za mart 53.500 dinara
    [2026-06-02] Sara preuzela iznos od 16.800 eur za rente koje je platila unapred obzirom da je raskinula ugovor o zakupu -> Sonuç: RACUNI ZA APRIL PLACENI OD DEPOZITA KOJI SE ZADRZAVA ZA POKRIVANJE TROSKOVA
    [2026-06-16] Cistacica je bila i detaljno ocistil stan, kao i covek za dubinsko pranje namestaja
    [2026-06-24] Useljeni novi stanari, placena renta za period od 24.06.-23.06.2026.
    [2026-06-28] Odnet novim stanarima jos jedan kljuc sa tagom, sada su kod njih 3 kljuca, dva sa tagom i jedan bez
    [2026-07-29] Placena renta za avgust i septembar 4.000 eur -> Sonuç: Za period od 24.07.-23.09.2026.
    [2026-08-28] Placeni racuni za jul, dato 320 eur i 200 din
    [2026-09-22] Posteljine koje su bile u firmi u dve Ikea plavim kesama su prebacene u ostavu broj 081 u Rivieri
    [2026-09-25] Placena renta za oktobar i novembar ( 24.09.-23.11.) kao i racuni za avgust u iznosu od 278 eur -> Sonuç: Takodje platili su racune za period od 7 dana u junu kada su se uselili ( 70 eura )
    [2026-01 Notu]: VLASNIK PLATIO
    [2026-04 Notu]: PLECNI RACUNI OD DEPOZITA
    [2026-07 Notu]: renta za period 24.06.-23.07.
    [2026-08 Notu]: 24.07.-23.08.
    [2026-09 Notu]: 24.08.-23.09.
    [2026-10 Notu]: 24.09.-23.10.
    [2026-11 Notu]: 24.10.-23.11.', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Parking (Kalan)", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity (Kalan)", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance (Kalan)", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Parking", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Infostan (Kalan)", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        '47013784-dd68-567f-942a-90c43141820a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'ASSERIA STONE PARTNERS', 'C 8.35 LANDMARK', 'C 8.35 LANDMARK', 'БУЛЕВАР КРАЉА АЛЕКСАНДРА 142 СТ. Ц.8.35, Belgrade, Serbia', 'Beograd', 'EUR',
        3200.0, 3200.0, true, '--- Dnevnik Događaja ---
    [2025-06-14] Uselili su se short term zakupci na period od 14.06-01.07 i platili iznos od 3400 eur
    [2025-07-22] Potpisan ugovor o zakupu. Zakupac uplatio depozit u iznosu od 3200 eur, 1600 eur za period 22.07.-22.08 (kirija sa 50% popusta) i 930 eur za period od 23.08-31.08. (deo kirije za 9 dana avgusta po punoj ceni zakupnine srazmerno broju dana)
    [2025-07-23] Izneti su singl kreveti iz sobe i preneti u ostavu br.12 na -1, u B kulu BW Residences
    [2025-07-23] Gabrijela nas je obavestila da masina za sudje izlazi iz lezista i da treba da se pricvrsti, takodje i da u tom stanu nema usisivaca.
    [2025-08-05] Zakupac istakao zahtev da o svom trosku skine luster iz dnevne sobe i da stavi svoj, rekao da ce pri izlasku iz stana da vrati u prvobitno stanje
    [2025-10-06] Zakupac dao tri mesečne kirije unapred, za oktobar, novembar i decembar 2025. god. -> Sonuç: Platio racune za avgust (racuni iznose 40.075,79 rsd / 343 eur) tako da zakupac ima pretplatu 57 eur + stara pretplata 14 eur
    [2025-12-19] Dao novac za račune za septembar, oktobar i novembar -> Sonuç: Ukupan iznos računa 135.8800 din, on je dao 140.000 din tako da ima pretplatu 4.120 din
    6700 renta jan i feb i 300 e avans za račune
    [2026-02-27] Zakupac dao rentu za mart 3200 e i novac za racune za januar -> Sonuç: Dao 50e vise tako da ima pretplatu + pretplata iz prethodnog perioda 331e
    [2026-04-02] Poslata poruka za placanje rente za april i racune za februar
    [2026-04-06] Placena kirija za april 3200 + racuni za februar 700e -> Sonuç: Dao 2.140 dinara vise + pretplata iz prethodnog perioda 381e
    [2026-05-04] Placena kirija za maj 3200 + racuni za mart 74.000 dinara
    [2026-06-03] Placena kirija za maj 3200 + racuni za mart 600 eur + 2.000 dinara -> Sonuç: Dao 1000 dinara vise
    [2026-06-09] Rade se pozalio da ne radi interfon, majstor ce doci da popravi jer je zgrada u garanciji
    [2026-07-01] Rade platio rentu za jul 3.200 eur + dao novac za racune za maj 570 eur
    [2026-08-04] Rade platio rentu za avgust, septembar i oktobar 9.600 eur + novac za racune za jun 470 eur
    [2026-09-10] Placeni racuni za jul u iznosu od 56.200 dinara
    [2026-10-07] Placeni racuni za avgust 500 eur + 1000 dinara', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Parking", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        '64ba78b5-a1b9-5157-9070-5481c640b124', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'ASSERIA STONE PARTNERS', 'B 7.37 LANDMARK', 'B 7.37 LANDMARK', 'БУЛЕВАР КРАЉА АЛЕКСАНДРА 142А СТ. Б.7.37, Belgrade, Serbia', 'Beograd', 'EUR',
        1200.0, 2400.0, true, '--- Dnevnik Događaja ---
    [2025-06-02] Zakupac je tražio dve komode pored kreveta,prostirke za kupatilo i kantu u kupatilu. Trazio je cediljku za tanjire i escajg,takodje stalak za ubrus,slanik i krpe za kuhinju. Prostirke ispred stana i na ulazu u stan je tražio. Za dnevni boravak želi komodu. -> Sonuç: Nabavili smo nocne stocice.
    zakupac u januaru 2026 godine, platio zakup za period 25.12.2025 do 24.01.2026 i platio racune za novembar 21.000 rsd
    [2026-03-11] Branko dao za račune za januar 26.000 dinara i rentu za mart 1.400 dolara (1.200 eura) -> Sonuç: Predato Jovani
    [2026-03-16] Zakupac trazi snizenje cene rente sa 1200 na 1000 eur uz obrazlozenje da je nasao jeftiniji stan. Poslat mail Jovani za konsultaciju
    [2026-03-27] Zakupac platio rentu 1000 EUR + racune za februar 27.500 dinara -> Sonuç: Predato Jovani
    [2026-03-30] Odradjen aneks za smanjenje rente sa 1200 na 1000, dati mu da potpise kada se sledeci put budemo nalazili za novac
    [2026-04-26] Branko je rekao da ce u sredu doneti novac jer je na putu
    [2026-04-28] Placena renta za period od 25.04. - 24.05.2026 -> Sonuç: 1000 eur renta plus 25.530 dinara racuni za mart
    [2026-05-29] Placena renta za period od 25.05. - 24.06.2026 -> Sonuç: 1000 eur renta + 24.800 dinara racuni za april
    [2026-05-29] Zakupac je zatrazio komodu i televizor za spavacu sobu
    [2026-06-24] Porucena komoda iz jyska kao i televizor za spavacu sobu -> Sonuç: Poruceno je sa kartice Asserie tako da je automatski placeno
    [2026-06-29] Preuzeta renta za period od 25.06.-24.07 100 eur + novac za racune 24.800 din -> Sonuç: Za racune je dao 2.500 manje
    [2026-07-08] Nakon nestanka struje u stanu, rerna nije radila, danas je bio ovlasceni serviser i popravio rernu -> Sonuç: Obzirom da je u garanciji rerna, nije bilo naplate
    [2026-08-11] Preuzeta renta za period od 25.07.-24.08 -> Sonuç: 1000 eur renta + 24.600 din ( uracunat i dug od 2.500 din )
    [2026-09-08] Preuzeta renta za period 25.08.-24.09. -> Sonuç: 1000 eur renta + 21.300 racuni jul
    [2026-10-08] Preuzeta renta za period od 25.09.-24.10. -> Sonuç: 1000 eur renta + 21.00 dinara racuni avgust
    [2026-01 Notu]: 25.12-24.01
    [2026-02 Notu]: 25.01-24.02
    [2026-03 Notu]: 25.02-24.03
    [2026-04 Notu]: 25.03.-24.04.
    [2026-05 Notu]: 25.04.-24.05.
    [2026-06 Notu]: 25.05.-24.06
    [2026-07 Notu]: 25.06.-24.07.
    [2026-08 Notu]: 25.07.-24.08.
    [2026-09 Notu]: 25.08.-24.09.
    [2026-10 Notu]: 25.09.-24.10.', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Parking", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        'a9a4d27b-b3d3-5572-a0f4-0ab22a7b32d6', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'ASSERIA STONE PARTNERS', 'B 8.47 LANDMARK', 'B 8.47 LANDMARK', 'БУЛЕВАР КРАЉА АЛЕКСАНДРА 142/1 ГА. 87 /5, Belgrade, Serbia', 'Beograd', 'EUR',
        2000.0, 3000.0, true, '--- Dnevnik Događaja ---
    [2025-06-10] Zakljucen ugovor o zakupu. Uplaceno: depozit 2200 eur, 410 eur avansno za racune i prva zakupnina za deo juna 1450 eur 10.06.-30.06
    [2025-06-10] Zakupac je istakao sledeće primedbe: Uklanjanje tapeta. Zatvoriti uticnice u glavnoj spavacoj sobi. Double bed u gostinjskoj sobi i manji TV u istoj sobi. Na ulazu u ormaru fale usporivači. Push sistem za garderober fali u glavnoj spavacoj sobi i usporivaci. Problem sa internetom. Namestaj za terasu. Pribor za jelo i kuhinjska oprema. Takodje fale peškiri,ogrtači,pegla i usisivač. Tražila je sef. -> Sonuç: Obaveštena je da zahtev za internet mora sama da podnese. Kupljen joj je sef. Nabavili smo joj double bed za gostinjsku sobu. Nabavili smo joj TV za gostinjsku sobu. Nabavili smo peglu.
    [2025-06-11] Zakupac je istakao sledeće primedbe:Nema usporivač ispod sudopere. Orman na ulazu udara. U gostinjskoj sobi vire šrafovi. Nema stoper za vrata u spavaćoj sobi. Fali kanta za djubre,sušač za veš,aparat za kafu i toster. Zakupac je trazio otvorene police za cipele u master sobi pored ormana. -> Sonuç: Nameštena joj je kanta i ugradjena joj je u gostinjskoj sobi u ormanu. Električar je došao za prekidače i ugradio usporivač na ulazu. Isporucene su joj otvorene police za cipele u master sobi. Nabavili smo zakupcu toster,aparat za kafu.                                                                                                             •        Toster okvirna cena 100 eur 
    •        Kafe aparat okvirna cena 100 eur 
    •        Žica-sušač za veš okvirna cena 50 eur 
    •        Sef - okvirna cena 120 eur 
    •        Mali TV za gostinsku sobu (okvirno 300 eur)
    [2025-11-14] Milica dala rentu za novembar, dala je 2.200 EUR, kirija joj je 1.150 EUR -> Sonuç: Ostala dužna da plati račune za septembar u iznosu od 27.906,89 din (ali ima pretplatu 35 EUR)
    Milica je donela 25.02. iznos od 79.100 za racune za novembar i decembar 2025
    Duguje racune za januar i februar kao i rentu za januar i februar 2026 -> Sonuç: Ukupno 4300 eur plus racuni januar Дин. 59,821.84 plus za februar
    Opomene su isle svaki drugi dan pocev od 10.01.2026
    Ukupno dugovanje pristiglo do sad 4300 eur plus racuni za januar
    [2026-03-17] Milica zvala i obavestila da ce isplatiti dug u petak 20.03.2026
    [2026-04-04] Usao novi zakupac, dala prvu rentu u iznosu od 2000 EUR + 3000 EUR depozit
    [2026-04-29] Slavica je zamolila da se dubinski opere nameštaj u dnevnoj sobi, kao i tepisi jer su dosta pokupili miris cigara od prošlog zakupca. -> Sonuç: Dubinsko pranje nameštaja je odradjeno, iznosilo je 4.000 dinara i plaćeno je u kešu. Tepisi su takodje odneti, za njih je odradjen predračun, iznos je 10.206 dinara, poslato je Jovani da plati
    [2026-05-06] Preuzeta renta za 3 meseca unapred, za maj, jun i jul -> Sonuç: 6.000 eur
    [2026-05-08] Slavici ostavljen kljuc od stana na Terraces-u, zatrazila je jos jedan jer joj je dat samo jedan kljuc
    [2026-06-03] Slavica uplatila 34.000 za racune za april
    [2026-07-03] Placeni racuni za maj u iznosu od 40.250 dinara
    [2026-08-06] Placena renta za avgust 2.000 eur + racuni za jun u iznosu od 31.000 din
    [2026-09-08] Placena renta za septembar 2.000 eur + racuni za jul u iznosu od 32.400 rsd
    [2026-10-13] Placena renta za oktobar 2.000 eur + racuni za avgust 32.000 + 5 eur', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'ASSERIA STONE PARTNERS', 'A 5.17 LANDMARK', 'A 5.17 LANDMARK', 'БУЛЕВАР КРАЉА АЛЕКСАНДРА 142/2 ГА. 136 /5, Belgrade, Serbia', 'Beograd', 'EUR',
        2450.0, 3675.0, true, '--- Dnevnik Događaja ---
    [2025-11-21] Platila račune za oktobar - dala 42.000 dinara
    [2025-12-12] Platila rentu za decembar 2.450 EUR i dala još 250 EUR više - ukupno dala 2.700 EUR -> Sonuç: 250 EUR ostaviti pa platiti sledeće račune
    [2026-01-09] Platila rentu za januar i račune za novembar, u to ulazi i 250 EUR od pretplate od prethodnog meseca -> Sonuç: Ima pretplatu nekih 13 EUR
    [2026-02-11] Platila rentu za januar i račune za decembar -> Sonuç: Nije dala tačan iznos, fali 212 eura ili 25.000 dinara. Dala je 149.500. dinara i 505 eura
    [2026-02-18] Maja dala 212 eura koji su falili
    [2026-03-06] Platila rentu za mart 2.450 EUR i dala 870 eur za racune -> Sonuç: Dala je 90e vise tako da je u pretplati
    [2026-04-06] Placena renta za april 2.450 EUR i dala 70.000 dinara za racune -> Sonuç: Pretplata od proslog puta 90e
    [2026-05-06] Placena renta za maj 2.450 EUR + 600 eur za racune za mart
    [2026-06-05] Placena renta za jun + racuni za april -> Sonuç: Dato je 1000 eur + 229.500 dinara, ja sam iz pretplate dodala 20 eur jer su dali toliko manje za racune, sada im ostaje pretplata od 70 eur
    [2026-07-08] Placena renta za jul + racuni za maj -> Sonuç: Dato je 2.350  eur + 72000 dinara, dodato 20 eur iz pretplate
    [2026-08-07] Placena renta za avgust  + racuni za jun -> Sonuç: 1.000 eur + 170.000 din renta + 53.520 din za racune
    [2026-09-09] Placena renta za septembar + racuni za jul -> Sonuç: 2.450 eur + 55.000 din
    [2026-10-13] Placena renta za oktobar + racuni za avgust -> Sonuç: 2450 eur + 56000 dinara', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Parking", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        'cbb8caa3-60d2-5462-b18d-deb10d72e925', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', NULL, 'VILA SREMCICA', 'VILA SREMCICA', 'VILA SREMCICA, Belgrade, Serbia', 'Beograd', 'EUR',
        4500.0, 9000.0, true, '--- Dnevnik Događaja ---
    Prozori u podrumu ne rade dobro, ulazi voda kada je kiša. Vlaga u spavaćoj sobi. Problem sa bazenom- smanjeju se nivo vode.
    Zakupac je 1.09.2025. nagovestio da izlazi zaključno sa 30.09. 2025.
    Novi zakupac je zatražio ugradnju i zidanje djakuzija u podrumu u iznosu od 10.000 EUR. Pokrivka za bazen 1.800 EUR u našem trošku.
    [2025-10-02] Zakupci su predali iznos od 9000 eur za depozit (dve kirije), a u subotu ili nedelju radimo primopredaju sa njima kada ce mi predati I iznos za prvu rentu (treba da im se preracuna za period od 05.10 pa do kraja meseca, po mom proracunu to je 3920 EUR) -> Sonuç: Za Sremcicu treba Jovana da preda iznos od 100 eur koji bi trebalo da odbije od depozita prethodnog zakupca za čišćenje, osim toga od tog depozita treba da odbijemo I iznos za racune kada dobijemo od Nikole Korde taj iznos. Za hemiju za ciscenje donela racun 1800 dinara, taj novac mi je vec dala. Za Sremcicu mi je Jovana predala iznos od 1722 eur koji sam predala bazendziji za pokrivku za bazen (priznanica u prilogu, a original cu preuzeti kad ga vidim)
    [2025-11-04] Išlo se u Sremčicu da se uzme renta. Danas se takođe popravljaju radijatori u kupatilima i garaži i podešava se struja, tj majstori i električari podešavaju da struja i wi fi rade u svim sobama
    Proveriti da li je Nikola kupio poštansko sanduče za Sremčicu
    [2026-01-12] Marco doneo rentu za januar 4.500 EUR
    [2026-02-18] Dali rentu za februar - 4.500 EUR
    [2026-03-09] Poslat im je podsetnik za placanje rente i uputstvo za samoocitavanje brojila.
    [2026-03-16] Placena renta za mart 4.500 EUR
    [2026-04-02] Poslat mail za placanje rente
    [2026-04-06] Poslata poruka na wa, nije odgovorio, nakon toga se Natasa cula sa Markom, rekao je u cetvrtak da se vidimo za rentu
    [2026-05-06] Pokupljena renta za maj u iznosu od 4.500 eur
    [2026-06-05] Pokupljena renta za jun u iznosu od 4.500 eur
    [2026-09-29] Odradjeno kosenje trave i ocupavanje trave i taj trosak je iznosio 150 eur
    [2026-10-01] Novi zakupci dali jedan depozit u iznosu od 3.900 EUR
    [2026-10-02] Dali deo depozita u iznosu od 1.700 EUR i dali kiriju u isnosu od 3.900 EUR', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', NULL, 'TERRACES 1304', 'TERRACES 1304', 'TERRACES 1304, Belgrade, Serbia', 'Beograd', 'EUR',
        4000.0, 8000.0, true, '--- Dnevnik Događaja ---
    [2026-01-11] Platili rentu za 3 meseca unapred
    [2026-01-15] Plaćeni računi za decembar
    Pre ngo što su se zakupci uselili u stan, organizovano je i plaćeno detaljno čišćenje stana
    [2026-02-16] Zakupci prijavili da im se pokvarila mašina za pranje veša (mašina nije u garanciji više) -> Sonuç: Kvar je prijavljen servisu za popravku mašine
    [2026-02-19] Serviseri su bili da poprave masinu, promenjena je guma i provereno je da masina ne ispusta vodu -> Sonuç: Placeno je na licu mesta 10.000
    [2026-03-10] Pokupljen racun za struju, racun iznosi 4843,22, ali je u pretplati 2814,78
    [2026-03-13] Placeni racuni za februar -> Sonuç: Razmenjeno 750e za racune
    [2026-04-06] Platio rentu jos 3 meseca unapred -> Sonuç: 12.000 EUR
    [2026-04-20] Placeni racuni za mart ( bez struje i mts) u iznosu od 78.918,02 -> Sonuç: Razmenjeno je 690 eur
    [2026-04-21] Stigao je racun za MTS uvecan, zvali smo i dobili povratnu informaciju kako se na jednom racunu nalazi racun i za Hercegovacku i za adresu gde vlasnik zivi
    [2026-05-08] Razmenjeno 100 eur da bi se platio MTS racun -> Sonuç: Ostao kusur 1000 dinara
    [2026-05-21] Razmenjeno je 850 eur od agencijske provizije za racune i placeni svi racuni -> Sonuç: Dobijeno 99.025 dinara, kusur 2.290 dinara
    [2026-06-26] Placeni racuni za maj u iznosu od 88.708,52 dinara', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Internet/TV", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Parking", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        '500002db-410a-5fc6-b10f-1cdd119ed20a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'ASSERIA STONE PARTNERS DOO', 'BW QUARTET C006', 'BW QUARTET C006', 'ЛУКЕ ЋЕЛОВИЋА ТРЕБИЊЦА 19 СТ. 6, Belgrade, Serbia', 'Beograd', 'EUR',
        1300.0, 1800.0, true, '--- Dnevnik Događaja ---
    Stan je detaljno sredjen i ociscen, odradjeno je dubinsko ciscenje namestaja, izbacene stvari u tri kutije koje su stavljene u ostavu od Aque 1807. Takodje, postavljen je alarm na ulazna vrata, svi računi su skenirani i prosledjeni Jovani -> Sonuç: Troskovi su iznosili: - 8.000 dinara za iznosenje stvari                          - 3.500 dinara dubinsko ciscenje    - 5.577.30 dinara jastuci i jorgan
    [2026-06-10] Primopredaja kljuceva i useljenje novih zakupaca
    [2026-07-06] Placena renta jul u iznosu od 1.300 eur
    [2026-07-07] Zakupac se pozalio kako prskalice prskaju umesto na povrsinu trave, prskaju po terasi, poslat je mail Beogradu na vodi, kao i Facility pointu, i pozvan je upravnik zgrade, cekamo majstore
    [2026-08-05] Pokupljena renta za avgust, kao i novac za racune za period od 10.06. - 30.06 -> Sonuç: 1300 eur renta + 24400 din za racune
    [2026-09-08] Pokupljena renta za septembar, kao i novac za racune za jul -> Sonuç: 1300 eur + 30.270 din
    [2026-10-07] Pokupljena renta za oktobar i racuni za avgust -> Sonuç: 1300 eur renta + 240 eur racuni
    [2026-06 Notu]: Plaćena renta za period od 10.06. - 30.06.', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity (Kalan)", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance (Kalan)", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Internet/TV", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Internet/TV (Kalan)", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Infostan (Kalan)", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'ЂОРЂЕВИЋ САША', 'BW RESIDENCES 1704', 'BW RESIDENCES 1704', 'ХЕРЦЕГОВАЧКА 14Б СТ. 174, Belgrade, Serbia', 'Beograd', 'EUR',
        2500.0, 3500.0, true, '--- Dnevnik Događaja ---
    [2026-05-10] Novi zakupac je pri ulasku u stan platio depozit u iznosu od 3.500 eur i prvu rentu u iznosu od 2.500 -> Sonuç: Ovu rentu cemo racunati kao rentu za jun, dok je 10.06.2026. platio 1695 eur i to ce biti renta za period od 21 dan u maju tj od 11.05.-31.05.
    [2026-06-10] Platio rentu za period od 21 dan u maju, dao je 200.000 dinara
    Zakupac prijavio problem - ne radi mali bojler i odredjena svetla -> Sonuç: Cekamo da posalje mail sa objasnjenjem kvara
    [2026-07-01] Placena renta za jul 2.500 eur + racuni za maj u iznosu od 29.800 dinara
    [2026-08-03] Placena renta za avgust 2.500 eur + racuni za jun u iznosu od 59.700 dinara -> Sonuç: Takodje dodao je 8.600 za info stan u maju
    [2026-09-02] Placena renta za septembar 2.500 eur + racuni za jul 58.700 dinara
    [2026-10-13] Placena renta za oktobar 2.500 eur + racuni za avgust 60.000 dinara -> Sonuç: 352.200 dinara dato
    [2026-06 Notu]: RENTA ZA PERIOD OD 11.05.-31.05.2026', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity (Kalan)", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance (Kalan)", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Internet/TV", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Internet/TV (Kalan)", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Infostan (Kalan)", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        '964b18b7-4c64-54a1-b9ee-35f5ad7df0ba', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', NULL, 'BW PERLA 101', 'BW PERLA 101', 'BW PERLA 101, Belgrade, Serbia', 'Beograd', 'EUR',
        2800.0, 2800.0, true, '--- Dnevnik Događaja ---
    [2026-08-05] Placena i prva renta i depozit, predato Jovani
    [2026-08-01] Placena renta za septembar i oktobar u iznosu od 5.600 eur', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        'd97b99c6-9b85-56ba-82fd-d4349b846268', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', NULL, 'BW PERLA 303', 'BW PERLA 303', 'BW PERLA 303, Belgrade, Serbia', 'Beograd', 'EUR',
        3350.0, 6700.0, true, '--- Dnevnik Događaja ---
    [2026-08-05] Od novih zakupaca pokupljen depozit u iznosu od 1.000 eur i predat danas jovani
    [2026-08-11] Preuzet ostatak depozita 5700 eur kao i renta za period od 11.08.-31.08. 2.270 eur -> Sonuç: Dali ukupno 8.100 eur, ostaje pretplata 30 eura
    Masina za susenje iz 303 prebacena u 2301, a iz 2301 u 303
    [2026-09-01] Placena renta za septembar u iznosu od 3500 eur ( dali 3.470 eur i imaju pretplatu 30e od proslog meseca
    [2026-10-01] Placena renta za oktobar u iznosu od 3350 eur -> Sonuç: Otkazali su drugo pm, tako da je sada renta 3.350 eur
    [2026-08 Notu]: Renta za period 11.08.-31.08', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        '6c87c83b-3315-5079-8fa3-96b2cf34b920', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', NULL, 'BW PERLA 505', 'BW PERLA 505', 'BW PERLA 505, Belgrade, Serbia', 'Beograd', 'EUR',
        4000.0, 4000.0, true, NULL, '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "bank_transfer"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "bank_transfer"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "bank_transfer"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        '9c88e542-8da5-5fe4-a661-111e2e059b1a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', NULL, 'BW PERLA 804', 'BW PERLA 804', 'BW PERLA 804, Belgrade, Serbia', 'Beograd', 'EUR',
        3900.0, 3900.0, true, '--- Dnevnik Događaja ---
    [2026-08-01] Useljeni novi stanari, placena prva renta  i depozit u visini od 3.900 eur -> Sonuç: Predato Jovani
    [2026-09-01] Placena renta za septembar u iznosu od 3.900 eur
    [2026-10-01] Placena renta za oktobar u iznosu od 3.900 eur', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        '2e42fd7e-21e3-56d5-ad1c-4a3b7b76147b', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', NULL, 'BW PERLA 2301', 'BW PERLA 2301', 'BW PERLA 2301, Belgrade, Serbia', 'Beograd', 'EUR',
        3350.0, 6700.0, true, '--- Dnevnik Događaja ---
    [2026-09-15] Useljeni novi zakupci u stan, placena renta za sepembar, period od 15.09. -  30.09. u iznosu od 1.785 eur + renta za oktobar u iznosu od 3350 eur -> Sonuç: Takodje, placen depozit u visini dve zakupnine 6.700 eur
    [2026-09-23] Svo posudje, serpe, case i usisivac su prebaceni u ostavu riviere broj 081, u dve braon kutije i jedne kutije od bojlera
    [2026-09-29] Crkla masina za sudove, pozvan je ovlasceni servis Bosh i dolaze danas u 12 da poprave, takodje ostavljena i sipka za ormar koju bi danas trebali da namontiraju', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        '56504287-7bba-5606-b530-62ee89ebd950', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', NULL, 'BW PERLA 2401', 'BW PERLA 2401', 'BW PERLA 2401, Belgrade, Serbia', 'Beograd', 'EUR',
        0.0, 0.0, true, NULL, '[{"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        '500755dd-4e28-51cd-afed-2085781fd68f', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', NULL, 'BW RIVIERA 206', 'BW RIVIERA 206', 'BW RIVIERA 206, Belgrade, Serbia', 'Beograd', 'EUR',
        5000.0, 5000.0, true, '--- Dnevnik Događaja ---
    [2026-07-30] Placen prvi deo depozita 5.000 eura -> Sonuç: Predato Jovani
    [2026-08-27] Placena renta za septembar 5.000 eur
    [2026-10-02] Placena renta za oktobar 5.000 eur', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        '458a1035-8b78-53b8-9313-768d6c5a672a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', NULL, 'BW RIVIERA 1004', 'BW RIVIERA 1004', 'BW RIVIERA 1004, Belgrade, Serbia', 'Beograd', 'EUR',
        4850.0, 4850.0, true, '--- Dnevnik Događaja ---
    [2026-08-06] Useljen stanar u 1004 i predati kljucevi', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "bank_transfer"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "bank_transfer"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "bank_transfer"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        '85f588d5-a1c2-566a-b756-c4ce698dbca6', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', NULL, 'BW RIVIERA 1104', 'BW RIVIERA 1104', 'BW RIVIERA 1104, Belgrade, Serbia', 'Beograd', 'EUR',
        4500.0, 6750.0, true, '--- Dnevnik Događaja ---
    [2026-08-10] Pokupljen depozit u iznosu od 5.750 eur kao i renta za period od 15.08.-31.08. u iznosu od 2.470 eur
    [2026-09-08] Placena renta u iznosu od 4.460 eur, odbijeno je 40 eur od pune cene rente jer su platili ciscenje
    [2026-10-07] Placena renta za oktobar u iznosu od 4.500 eur
    [2026-08 Notu]: Renta za period od 15.08.-31.08.', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        'b34a30ae-b228-5be0-9b59-21d8980ac274', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', NULL, 'BW RIVIERA 1304', 'BW RIVIERA 1304', 'BW RIVIERA 1304, Belgrade, Serbia', 'Beograd', 'EUR',
        4300.0, 8600.0, true, '--- Dnevnik Događaja ---
    [2026-08-05] U utorak 04.08. preuzet depozit u iznosu od 1.000 eur, i  predat danas Jovani
    [2026-08-10] Preuzet ostatak depozita u iznosu od 7.600 eura kao i renta za period od 10.08.-31.08. u iznosu od 3.060 eur -> Sonuç: dao 10.700 eur, ostaje pretplata 40 eur
    [2026-09-08] Placena renta u iznosu od 4.260 eur, imali pretplatu 40 eur od proslog meseca
    [2026-10-02] Placena renta za oktobar 4.300 eur
    [2026-08 Notu]: Renta za period 11.08. - 31.08.', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        '21a7b98f-23fe-5371-9895-7dfbcfd3e050', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', NULL, 'BW RIVIERA 2104', 'BW RIVIERA 2104', 'BW RIVIERA 2104, Belgrade, Serbia', 'Beograd', 'EUR',
        4450.0, 8600.0, true, '--- Dnevnik Događaja ---
    [2026-08-04] Potpisan ugovor sa novim zakupcem, placen depozit u iznosu od 8.600 i prva renta u iznosu od 4.450 eur -> Sonuç: Predato Jovani
    [2026-09-09] Placena renta za septembar u iznosu od 4.000 eur, odbijena mu je razlika za prvih 5 dana u avgustu i ostao je duzan 20 eur
    [2026-10-02] Placena renta za oktobar 4.450 eur, plus 20 eur dug od proslog meseca -> Sonuç: Dao 4.500 eur, ostaje pretplata 30 eur
    [2026-10-16] Uzet kljuc i dva taga iz kancelarije i data Ivanu, jedan je kljuc ostao na recepciji tako da mu i taj dajem', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        'e87ef13e-8e35-52b6-a84f-2acdf2dd72aa', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', NULL, 'BW RIVIERA 2203', 'BW RIVIERA 2203', 'BW RIVIERA 2203, Belgrade, Serbia', 'Beograd', 'EUR',
        4500.0, 9000.0, true, '--- Dnevnik Događaja ---
    [2026-08-07] Preuzet prvi deo depozita u iznosu od 4.500 eur -> Sonuç: Predato Jovani
    [2026-08-27] Preuzet drugi deo depozita u iznosu od 4.500 eur
    [2026-09-08] Placena renta za septembar 4.500 eur
    [2026-10-02] Placena renta za oktobar 4.500 eur', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        '12810dde-341d-5567-ad7b-7a4d060fe71f', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', NULL, 'BW RIVIERA 2304', 'BW RIVIERA 2304', 'BW RIVIERA 2304, Belgrade, Serbia', 'Beograd', 'EUR',
        4350.0, 6525.0, true, '--- Dnevnik Događaja ---
    [2026-08-14] Pokupljena renta u iznosu od 4.350 eur, Jovani dato za period od 14.08. - 31.08., ostatak ostavljen kod nas da prebacimo za sledeci mesec i da doplati koliko bude trebalo -> Sonuç: Dat i depozit u iznosu od 6.525 eur
    [2026-09-10] Placena renta za septembar -> Sonuç: Dodat iznos od 2.550 eur', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        'd21a40f8-ebd6-5314-b063-f69e818c54d2', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', NULL, 'ST. REGIS 2610', 'ST. REGIS 2610', 'ST. REGIS 2610, Belgrade, Serbia', 'Beograd', 'EUR',
        4200.0, 8400.0, true, '--- Dnevnik Događaja ---
    [2026-10-01] Useljeni novi stanari, placena renta 4.200 eur kao i depozit u iznosu od 8.400 eur', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        'd1945411-5842-52e2-9988-87b3cb9fa0fd', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', NULL, 'ST. REGIS 3306', 'ST. REGIS 3306', 'ST. REGIS 3306, Belgrade, Serbia', 'Beograd', 'EUR',
        2100.0, 3150.0, true, '--- Dnevnik Događaja ---
    [2026-09-15] Potpisan ugovor o zakupu, placen depozit u iznosu od 3.150 eur kao i prva renta u iznosu od 2.100 eur', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        '2958095f-a25c-58aa-ab38-476cb0f954eb', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', NULL, 'ST. REGIS 3504', 'ST. REGIS 3504', 'ST. REGIS 3504, Belgrade, Serbia', 'Beograd', 'EUR',
        2300.0, 4600.0, true, '--- Dnevnik Događaja ---
    [2026-09-16] Placena prva renta u iznosu od 1150 eur za period 16.09.-30.09 i depozit u iznosu od 4.600 eur
    [2026-10-01] Placena renta za oktobar u iznosu od 2.300 eur', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();

    INSERT INTO public.properties (
        id, agency_id, landlord_id, landlord_name, name, title, address, city, currency,
        default_monthly_rent, default_deposit_amount, is_detailed, description, expenses_template, created_at, updated_at
    ) VALUES (
        'a82a0252-9a9d-5479-8442-1fd16857102e', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', NULL, 'ST. REGIS 3607', 'ST. REGIS 3607', 'ST. REGIS 3607, Belgrade, Serbia', 'Beograd', 'EUR',
        0.0, 0.0, true, NULL, '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, now(), now()
    ) ON CONFLICT (id) DO UPDATE SET
        landlord_name = EXCLUDED.landlord_name,
        name = EXCLUDED.name,
        title = EXCLUDED.title,
        address = EXCLUDED.address,
        description = EXCLUDED.description,
        default_monthly_rent = EXCLUDED.default_monthly_rent,
        default_deposit_amount = EXCLUDED.default_deposit_amount,
        expenses_template = EXCLUDED.expenses_template,
        updated_at = now();


    -- ------------------------------------------------------------------------------
    -- 2. CONTRACTS
    -- ------------------------------------------------------------------------------
    INSERT INTO public.contracts (
        id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
        token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
        status, expenses_config, tenant_notes, due_day, created_at
    ) VALUES (
        '6e6fa932-72d2-5516-9efd-2b77f51f6070', '054fc448-a11b-54fc-9f66-f6e913fe84d4', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'Narcis Bečirović', '+381694739860', NULL,
        'b3034ecd1f625f359d4399e863438797', '2025-11-20', '2026-11-19', 2500.0, 3700.0, 'EUR', 'EUR',
        'active', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Parking", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, 'Orijinal Kontrat: 2025-11-20 - 2026-11-19.
    --- Dnevnik Događaja ---
    Zakupac platio 2.850 EUR, 2.300 EUR renta za jul i računi bez struje su bili 470 EUR. Imao pretplatu od 9.160 RSD -> Sonuç: ZAKUPAC NIJE PLATIO STRUJU ZA MAJ, JUN, JUL I AVGUST
    [2025-08-04] Od pretplate u iznosu oD 9.160 RSD odbijeno 4074 RSD za internet, ostalo 5136 RSD
    [2025-08-08] Placen je internet za 104 Terraces za jul 2025 u iznosu 2040 rad + 60 rsd provizija, ukupno 2100 rsd, iskoriscena pretplata koju ima (5136 rsd), tako da pretplata sada iznosi 3036 rsd.
    [2025-08-13] Zakupac obavešten da treba da plati 2.300 EUR rentu za avgust, 51.580,82din računi za jun i 55.247,54 računi za jul (obavešten je da za oba meseca nisu stigli računi za struju) -> Sonuç: Primljeno od zakupca 2.740 EUR, 2.300 renta za avgust i 440 EUR računi za jun
    [2025-08-29] Zakupac obavešten za rentu za septembar 2300 EUR i računi za jul 55.414,52 (475 EUR) bez struje
    [2025-09-17] Jovana poslala račun za EPS za avgust - 15.396,78 din
    [2025-10-02] EPS poslao korigovane račune. Jun - umesto 65.340,74 din iznos od 9.619,57 din. Jul - umesto 75.638,18 din iznos od 11.257,33 din
    [2025-10-10] Ukupno za EPS jun, jul i avgust je 310 EUR, a pretplata koju zakupac ima je 225 EUR -> Sonuç: Treba da doplati 85 EUR za EPS
    [2025-10-20] Zakupac dao novac za rentu i 200 EUR za račune -> Sonuç: Duguje još 370 EUR regularno + još 85 za EPS
    [2025-11-01] depozit zakupca - 4600e: 2300e renta za novembar, 550e racuni septembar, 510e racuni oktobar (ukljucujuci internet),550e racuni novembar (bez interneta),350e dug od avgustovskih racuna,120e ciscenje stana, 85e doplata za struju,ukupni troskovi 4465e, ostaje od depozita 135e
    [2025-11-19] Novi zakupci - Narcis Bečirović i Ana, useljavaju se 20.11.2025. Potpisan Ugovor o zakupu, i zapisnik o primopredaji. -> Sonuç: Prilikom potpisivanja, platili: prvu mesečnu zakupninu u iznosu od 2.500 EUR, kao i depozit u visini od 3.700 EUR.
    [2025-11-20] Zameniće se kreveti u stanu 104 i 207 u BW Terraces tako da će single krevet iz 207 da se prebaci u ostavu a bračni iz 104 u 207.
    [2025-11-24] Stanarka prijavila da joj ne radi mašina za pranje sudova.
    [2025-11-25] Angažovan majstor iz Bosch-a da popravi mašinu za sudove, mašina je popravljena. -> Sonuç: Popravka mašine plaćena 6.000 dinara
    [2025-12-03] Izneto iz stana: TV iz dnevne sobe, mikrotalasna i dve zlate stone lampe i preneto u stan 207
    [2025-11-27] Zakupac trazio dubinsko pranje duseka u master sobi -> Sonuç: Poslato je dubinsko, platila je sama 3000 rsd, odbiti im od kirije
    [2025-11-30] Tražila je da se kupi naddušek za master sobu -> Sonuç: Kupila je sama u Yisku i tražila je da joj se odbije od kirije 21.700 rsd
    [2025-12-19] Platila 2290 eura za period 20.12. do 19.01. Odbijeno joj je 210 eura za naddušek i dubinsko čišćenje dušeka. Za 11 dana novembra dala 200 eura za račune
    [2026-01-20] Platila 2.500 EUR rentu za period od 20.01. - 19.02.2026. + 650 eur za racune za decembar
    [2026-02-20] Platila 2.500 EUR rentu za period od 20.02. - 19.03.2026. + 705 eur za racune za januar
    [2026-03-20] Platila 2.500 EUR rentu za period od 20.03. - 19.04.2026. + 655 EUR za racune za februar
    [2026-04-21] Platila 2.500 EUR rentu za period od 20.4. - 19.05.2026. + 600 EUR + 1000 din za racune za mart
    [2026-04-21] Nataša je donela Ani usisivac iz stana C 7.28 jer se usisivac iz stana 104 pokvario, pokvaren usisivac je kod Natase u gepeku
    [2026-05-20] Platila 2.500 eur rentu za period od 20.05. - 19.06.2026. + 69.000 dinara za racune za april
    [2026-06-20] Platila 2.500 eur rentu za period od 20.06. - 19.07.2026. + 600 eur za racune za maj -> Sonuç: Pretplata 35 eur za naredni mesec
    [2026-07-20] Platila 2.500 eur rentu za period od 20.07. - 19.08.2026. + 500 eur i 600 din za racune za jun -> Sonuç: Dala je manje 35 eur koliko je ostala pretplata
    [2026-08-06] Krevet iz spavace sobe iz 104 Terraces prebacen u 2104 u Rivieru
    [2026-08-20] Platila 2.500 eur rentu za period od 20.08.-19.09.2026. + 350 eur za racune -> Sonuç: Ukupni racuni su 64.222,34 dinara, odbijeno 24.000 za komarnike
    [2026-09-17] Platila 2.500 eur rentu za period od 20.09.-19.10.2026. + 550 eur i 1.300 din za racune
    [2026-09-23] Sto i stolica  iz master spavace sobe prebacen u stan 2203 u Rivieru, dok je nocni stocic prebacen u 2401 Perla, a drugi nocni stocic je u stanu 207', 1, now()
    ) ON CONFLICT (id) DO UPDATE SET
        tenant_name = EXCLUDED.tenant_name,
        tenant_phone = EXCLUDED.tenant_phone,
        invitee_email = EXCLUDED.invitee_email,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        monthly_rent = EXCLUDED.monthly_rent,
        tenant_notes = EXCLUDED.tenant_notes;

    INSERT INTO public.contracts (
        id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
        token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
        status, expenses_config, tenant_notes, due_day, created_at
    ) VALUES (
        '427e672e-51b9-5343-b047-07ffe1aa9d1c', '4a1858ac-cd89-5ded-a31b-67561b05923f', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'Kostiantyn Kuzmenko', '+6382051720', NULL,
        'fb2e0f36f9b75e919302e71eeef97ea8', '2025-12-02', '2026-12-01', 2500.0, 5000.0, 'EUR', 'EUR',
        'active', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Parking", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, 'Orijinal Kontrat: 2025-12-02 - 2026-12-01.
    --- Dnevnik Događaja ---
    [2025-10-08] Računi za avgust 51.747,47 i da nedostaje račun za struju (obavešten u poruci)
    [2025-11-04] Tepisi iz dnevne sobe bili na dubinskom pranju -> Sonuç: Vraćeni u stan 04.11.
    [2025-11-05] Gledanje stana sa Vojinom iz agencije Brick pro u 10h
    [2025-11-06] Od depozita zakupca Jovana Avram, odbijeno je: 64.026,97 rsd za račune za septembar i 63.715,06 rsd za račune za oktobar, a ostatak u iznosu 1658 EUR iskorišćeno za deo rente za novembar
    [2025-12-02] NOVI ZAKUPAC - uselio se u stan Kostiantyn Kuzmenko -> Sonuç: Data prva renta u iznosu od 2.500 EUR i dva depozita 2.500 EUR x 2 = 5.000 EUR
    [2025-12-03] Potrebno je premestiti bracni krevet iz prve spavace (koji je tu stavljen iz prve spavace stana 104) u master sobu a sivi kozni krevet izbaciti iz stana i odneti u magacin u Sremcicu. Televizor, mikrotalasna i dve zlatne lampe iz stana 104 preneto u stan 207. Potrebno je kupiti nogice za tv koji je donet iz 104 i montirati tv u master spavacu na komodu -> Sonuç: Sivi krevet iz master sobe je ipak ostao u stanu a atlas krevet koji je iz stana 104 donet u gostinsku sobu prenet je u magacin u Banovce kod Nikole Korde. Takodje je iznet i radni sto i stolica u isti magacin. Nocni stocic i dve zlatne lampe iz stana 104 ostali su u gostinjskoj sobi stana 207
    [2026-03-10] Preuzeta kirija za mart u iznosu od 2500 EUR i novac za racune za januar u iznosu od 530e -> Sonuç: Zakupac je dao 3000 EUR i 5000 din, u pretplati je 1490 din
    [2026-03-26] Struja nije ocitana za februar, stavljen iznos kao i za prosli mesec
    [2026-04-01] Poslata poruka za placanje rente za april i racuna za februar
    [2026-04-06] Placena renta za april i racuni za februar -> Sonuç: 3100e dao, ima pretplatu iz prethodnog perioda
    [2026-04-29] Struja je stigla 33.337,37, obzirom da za februar struja nije ocitana, mi smo naplatili 8.805.30 kao za januar, tako da cemo od ovog iznosa oduzeti tih 8 hiljada i dodati osnovicu od 2.290,73 dinara -> Sonuç: Naplata za mart ce biti 26.822,80
    [2026-05-06] Placena renta za maj i racuni za februar -> Sonuç: 380.000 dinara dao, 1993,26 dinara pretplata
    [2026-06-02] Zakupac kontaktiran u vezi placanja rente za jun i racuna za april, ali nije u zemlji pa je rekao 9-10 juna da ce biti tu
    [2026-06-09] Preuzeta kirija za jun u iznosu od 2500 EUR i novac za racune za april u iznosu od 550e -> Sonuç: Pretplata 2.880 dinara
    [2026-07-09] Pruzeta kirija za jul + novac za racune za maj -> Sonuç: 355.000 dinara + 1500 din uzeto iz pretplate
    [2026-08-05] Preuzeta kirija za avgust + novac za racune za jun -> Sonuç: 2.500 eur renta + 500 eur i dve hilj za racune
    [2026-09-08] Preuzeta kirija za septembar + novac za racune za jul -> Sonuç: 2.500 eur renta + 600 eur za racune, ostaje pretplata 43 eur
    [2026-10-13] Preuzeta kirija za oktobar + novac za racune za avgust -> Sonuç: 2.500 eur renta + 520 eur racuni za avgust + pretplata', 1, now()
    ) ON CONFLICT (id) DO UPDATE SET
        tenant_name = EXCLUDED.tenant_name,
        tenant_phone = EXCLUDED.tenant_phone,
        invitee_email = EXCLUDED.invitee_email,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        monthly_rent = EXCLUDED.monthly_rent,
        tenant_notes = EXCLUDED.tenant_notes;

    INSERT INTO public.contracts (
        id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
        token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
        status, expenses_config, tenant_notes, due_day, created_at
    ) VALUES (
        'a71aaf01-64a9-5078-9f2b-49de6d570795', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'Myroslav Plakhotia', '+3816287800780', '515anything@gmail.com',
        'd8e7340bc3925431bb59ed90dec11829', '2025-04-29', '2026-10-30', 3600.0, 7200.0, 'EUR', 'EUR',
        'active', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Parking (Kalan)", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity (Kalan)", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance (Kalan)", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Parking", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Infostan (Kalan)", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, 'Orijinal Kontrat: 2025-04-29 - 2026-10-30.
    --- Dnevnik Događaja ---
    [2025-11-04] Miroslav je tražio daljinski i tražio je da se stakleni sto iznese iz njegovog stana -> Sonuç: Daljinski uzet iz stana 0901 West i biće mu odnešen
    Miroslav platio rentu za januar i račune za novembar
    [2026-02-11] Novi problem u stanu 1501, BW Simfonija. U pitanju je curenje vode, ovoga puta iz kupatila (ne sa terase).
    Komšinica iz stana 1401 me je obavestila da joj voda curi iz plafona u spavaćoj sobi i kaplje direktno na krevet.
    Odmah smo kontaktirali izvodjaca radova - Milenium tim. Obavešteni smo da zgrada više nije u garanciji, ali da će nam izaći u susret i izvršiti pregled. Nakon ulaska u stan i provere, utvrđeno je da voda zaista prodire iz našeg kupatila u stan ispod.
    Danas sam dobila poziv od Milenium tima sa pitanjem kada mogu da započnu radove u kupatilu. -> Sonuç: Zakupac je bio izrazito nezadovoljan zbog ponovnog uznemiravanja, a nakon informacije da će biti neophodna sanacija kupatila, izjavio je da namerava da napusti stan.
    [2026-02-23] Smanjena renta sa 3600e na 3200e -> Sonuç: Zbog nekoriscenja drugog kupatila zakupcu je smanjena renta
    Poslata mu je poruka u vezi placanja rente za mart, dana 09.03.
    Uraditi Aneks ugovora sa smanjenom rentom
    [2026-03-10] Preuzeta kirija od zakupca 3200 EUR
    [2026-04-01] Poslata poruka u vezi placanja rente i racuna za februar, takodje smo ga pitali da li zeli da produzi ugovor, obzirom da mu istice u aprilu -> Sonuç: Rekao je da zeli da produzi na 6 meseci, u cetvrtak 09.04. je dogovor da potpise
    [2026-04-09] Miroslav je dao 3.150 evra, i nije dao novac za racune, rekao je da ce dati u toku sledece nedelje, jer nije imao novac u kesu, tada ce dodati i 50e za kiriju
    [2026-04-25] Miroslav dao 4010 EUR za rentu za maj, i racune za februar -> Sonuç: 3200e renta za maj + 50e dug od rente za april + 760e racuni za februar
    [2026-05-04] Stavljena struja iznos kao za februar, posto nije za mart stigla
    [2026-05-19] Pokupljen novac za racune za mart 650 EUR -> Sonuç: Duguje 18 eur ukupno ( 7 eur za mart, za novembar 6e i za oktobar 5 e)
    [2026-06-05] Zakupac je kontaktiran u vezi placanje rente i racuna, nije u zemlji i bice tek oko 20-og
    [2026-06-26] Placena renta za jun i jul u iznosu od 6.400 eur + za racune za april i maj  dao 1260 eur -> Sonuç: Struja jos uvek nije stigla tako da sam mu uzela iznos kao i za prosli mesec
    [2026-07-28] Placena renta za avgust 3.200 eur + za racuni za jun 620 eur -> Sonuç: Struja stigla, tako da je doplatio i tu razliku od 2.000 din
    [2026-09-16] Placena renta za septembar 3.200 eur + za racuni za jul 670 eur
    [2026-10-16] Placena renta za oktobar 3.200 eur + za racuni za avgust 600 eur', 1, now()
    ) ON CONFLICT (id) DO UPDATE SET
        tenant_name = EXCLUDED.tenant_name,
        tenant_phone = EXCLUDED.tenant_phone,
        invitee_email = EXCLUDED.invitee_email,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        monthly_rent = EXCLUDED.monthly_rent,
        tenant_notes = EXCLUDED.tenant_notes;

    INSERT INTO public.contracts (
        id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
        token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
        status, expenses_config, tenant_notes, due_day, created_at
    ) VALUES (
        '3494ba18-d5ca-5ff6-a910-ffa21fded42a', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'Abstract doo', NULL, NULL,
        '48c1a4671ba65d7f89c0695edc9bdf27', '2024-08-01', '2026-12-31', 3000.0, 6000.0, 'EUR', 'EUR',
        'active', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "bank_transfer"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "bank_transfer"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "bank_transfer"}, {"name": "Parking", "receiver": "owner", "amount": 0.0, "payment_method": "bank_transfer"}]'::jsonb, 'Orijinal Kontrat: 2024-08-01 - 2025-07-31.
    --- Dnevnik Događaja ---
    [2026-02-18] Prijavljen problem na terasi stana - došlo je do odvajanja dela plafona terase – ukrasne obloge / fasadnog elementa (gipsane ili slične završne obrade), koji trenutno visi i postoji realna opasnost da padne.
    Prema onome što je vidljivo sa terase, deluje da dolazi do podlivanja vode sa terase stana iznad, usled čega se materijal na plafonu naše terase natapa i odlepljuje.
    Uraditi aneks ugovora
    [2026-03-18] Stigao je račun za struju u iznosu od 88.371,78 za ceo prethodni period za koji su zakupci u stanu
    [2026-04-02] Jovana mailom potvrdila da je placena renta za mart 27.03.2026.
    [2026-04-17] Jovana mailom potvrdila da je placena renta za april 16.04.2026.
    [2026-04-21] Jovana mailom potvrdila da su placeni racuni za januar i februar
    [2026-04-30] Jovana mailom potvrdila da su placeni racuni za decembar 2025. -> Sonuç: Uplacen iznos od 60.858,37
    [2026-05-14] Jovana mailom potrvdila da je placena renta za maj 2026 -> Sonuç: 3.000 eur
    [2026-07-30] Jovana mailom potvrdila da je placena renta za jun 2026
    [2026-08-24] Jovana mailom potvrdila da je placena renta za avgust 2026
    [2026-09-03] Jovana mailom potvrdila da su placeni racuni za mart, april i maj', 1, now()
    ) ON CONFLICT (id) DO UPDATE SET
        tenant_name = EXCLUDED.tenant_name,
        tenant_phone = EXCLUDED.tenant_phone,
        invitee_email = EXCLUDED.invitee_email,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        monthly_rent = EXCLUDED.monthly_rent,
        tenant_notes = EXCLUDED.tenant_notes;

    INSERT INTO public.contracts (
        id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
        token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
        status, expenses_config, tenant_notes, due_day, created_at
    ) VALUES (
        'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'Borko Grecic', NULL, NULL,
        '0396159485dd53cb934f07be30410171', '2026-05-13', '2027-05-12', 1800.0, 2700.0, 'EUR', 'EUR',
        'active', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Parking", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, '--- Dnevnik Događaja ---
    Obavesten 01.03., rekao da je na putu. Obavesten opet o iznosu za placanje, kirija mart i racuni za januar dana 09.03.
    [2026-03-19] Pokupljena kirija za mart 1800e plus 350e za racune -> Sonuç: pretplata 3000 dinara za racune
    [2026-04-01] Obavesten o placanju rente za april i racuna za februar, rekao da se nadjemo u ponedeljak
    [2026-04-06] Dao rentu za april 1800e plus racune za februar 39.000 -> Sonuç: u pretplati  3000 od prosli put
    [2026-04-29] Racun za struju nije stigao za mart, tako da je stavljena ista cifra kao i za februar
    [2026-05-08] Placena renta za maj i racuni za mart -> Sonuç: 1800 eur + 37.000 dinara za racune
    [2025-05-15] Usao je novi zakupac Borko - Obzirom na to da je Nikola platio rentu za ceo mesec, vraticemo mu razliku kada budu dospeli i racuni -> Sonuç: Placen je depozit 2.700 eur + prva renta 1800 eur
    [2025-05-28] Nikoli vracen depozit u visini jedne mesecne rente i razlika za maj obzirom da je ranije izasao iz stana a platio je ceo mesec -> Sonuç: 1.800 eur za depozit + 1045 eur za razliku
    [2026-06-03] Od Borka pokupljena renta u iznosu od 1050 eur za jun -> Sonuç: uzeto 300 eur za aprilske racune od 900 eur koji su ostali od Nikole da pokriju troskove
    [2026-07-01] Pokupljena kirija za jul 1800e + 13.400 dinara za racune za period od 13.05.-31.05
    [2026-07-31] Pokupljena kirija za avgust 1.800 eur + novac za racune za jun + deo info stana za maj za period od 14.05.-31.05. -> Sonuç: Ukupno 40.000 dinara
    [2026-08-03] Jovani dato 100 eur + 2000 din iz gladoviceve koverte za racune za maj od 01.05.-13.05.
    [2026-09-01] Placena renta za septembar 1800 eur + 32.200 din za racune za jul
    [2026-09-29] Bojler u stanu crkao, pozvan servis, odnosno morace novi bojler, jos uvek se ne zna cena
    [2026-10-01] Placena renta za oktobar (1.800 eur) kao i racuni za avgust 32.100 dinara
    Popravljen bojler u stanu, popravka je iznosila 16.900 dinara', 1, now()
    ) ON CONFLICT (id) DO UPDATE SET
        tenant_name = EXCLUDED.tenant_name,
        tenant_phone = EXCLUDED.tenant_phone,
        invitee_email = EXCLUDED.invitee_email,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        monthly_rent = EXCLUDED.monthly_rent,
        tenant_notes = EXCLUDED.tenant_notes;

    INSERT INTO public.contracts (
        id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
        token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
        status, expenses_config, tenant_notes, due_day, created_at
    ) VALUES (
        'ce1cf655-bc33-54e2-901e-3b949608ba6a', '3202a566-41ba-594d-8870-f5f37147e9a0', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'Aleksei Shkarin', NULL, 'shtompel.niki@gmail.com',
        'dca56f4f9921521dbb8adfeee8071f34', '2025-12-01', '2029-12-01', 2450.0, 3450.0, 'EUR', 'EUR',
        'active', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Parking", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, 'Orijinal Kontrat: 2025-12-01 - 2029-12-01.
    --- Dnevnik Događaja ---
    [2025-10-03] 2900e - renta za oktobar 2600e + racuni za avgust 300e (racuni su 38.661,26 + provizija 441.03 = ukupno 39.102,29 / 334e - pretplata 45e = 289e -> Sonuç: zakupac sada ima novu pretplatu 11e
    [2025-11-24] Popravljena balkonska vrata iz dnevne sobe i popravljena balkonska vrata iz master spavaće sobe -> Sonuç: Plaćeno sve 100 EUR
    [2025-11-25] Bila Boba da skine zavese, pa su iz perionice veša došli i pokupili zavese. Takođe, Nataša odnela sedalni deo ugaone garniture u Zemun na ušivanje, jer se rašila. -> Sonuç: Uslugu skidanja i nameštanja zavesa Bobi plaćamo 4.000 dinara, a pranje zavesa 34.970 dinara.
    [2025-11-26] Depozit od Gizem u iznosu od 3.900 EUR: - 2.600 EUR zakupnina za novembar, 350 EUR troškovi za septembar, 350 EUR troškovi za oktobar, 380 EUR troškovi za novembar -> Sonuç: Nakon svih ovih odbitaka, preostali iznos je 220 EUR koji je refundiran
    [2025-12-01] Pranje sofe plaćeno 4.000 dinara, ušivanje sedišta sofe plaćeno 3.000 dinara i dato čistačicama (2 čistačice po 8h) 16.000 dinara
    [2025-12-02] I mesečna kirija - 01.12 - 31.12. 2025. -> Sonuç: 2.450 EUR (1.900 EUR + 64.350 RSD)
    [2025-12-15] Računi za novembar plaćeni iz depozita od Gizem -> Sonuç: Naplatićemo i Nikolaju 10 dana računa za novembar
    [2026-01-21] Nikolaj platio račune za decembar - 55.200 dinara -> Sonuç: PREBACITI U NOVU TABELU
    [2026-02-04] Nikolaj dao kiriju za februar 2.450 eura -> Sonuç: PREBACITI U NOVU TABELU
    [2026-03-03] Placena kirija 2.450 eura za mart i racuni za januar -> Sonuç: 2.450 eur + 59.480 rsd
    [2026-04-02] Placena kirija 2.450 eura za april i racuni za februar -> Sonuç: 2.450 eur + 62.500 rsd
    [2026-04-28] Placena kirija 2.450 eur za maj i racuni za mart -> Sonuç: 2.450 eur + 57.660 rsd
    [2026-06-03] Placena kirija 2.450 eur za jun i racuni za april -> Sonuç: 2.450 eur + 52.860 rsd
    [2026-07-01] Placena kirija 2.450 eur za jul i racuni za maj -> Sonuç: 2.450 eur + 54.350 rsd
    [2026-08-05] Placena kirija 2.450 eur za avgust i racuni za jun -> Sonuç: 2450 eur + 51.640 rsd
    [2026-09-08] Placena kirija 2.450 eur za septembar i racuni za jul -> Sonuç: 2450 eur + 52.100 rsd
    [2026-10-01] Placena kirija 2.450 eur za oktobar i racuni za avgust -> Sonuç: 2450 eur + 58.810 rsd', 1, now()
    ) ON CONFLICT (id) DO UPDATE SET
        tenant_name = EXCLUDED.tenant_name,
        tenant_phone = EXCLUDED.tenant_phone,
        invitee_email = EXCLUDED.invitee_email,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        monthly_rent = EXCLUDED.monthly_rent,
        tenant_notes = EXCLUDED.tenant_notes;

    INSERT INTO public.contracts (
        id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
        token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
        status, expenses_config, tenant_notes, due_day, created_at
    ) VALUES (
        'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'Lidia Pavlova, Ivan  Senikov zakupac', '+6775291750', 'khvostovstvo@gmail.com',
        '2717271a111950a29f6391fd12c8043d', '2025-11-06', '2026-11-05', 2600.0, 5200.0, 'EUR', 'EUR',
        'active', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Parking", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, 'Orijinal Kontrat: 2023-11-06 - 2026-11-05.
    --- Dnevnik Događaja ---
    [2025-04-30] Zakupac se zalio na prljave prozore iako su bili alpinisti da ih ociste i trazio da se resi problem. -> Sonuç: Pronašla sam profesionalne čistače prozora koji poseduju adekvatnu opremu za čišćenje unutrašnjih površina. Radi se o ruskoj agenciji specijalizovanoj za usluge čišćenja.
    [0205-06-04] Zakupac je imao problema sa klimom. -> Sonuç: Organizovali smo ovlasceni servis klima uredjaja.
    [2025-10-06] Pokupljena kirija od zakupca Ivana, nije više 2600 eur nego 2500 eur
    [2025-12-05] Pokupljena kirija od zakupca
    [2025-01-08] Zakupac se više puta obratio zbog nečistoće u zgradi, prljavih spoljnih prozora i kvara ulaznih vrata zgrade -> Sonuç: Pozvan upravnik zgrade više puta i poslato više mejlova sa zahtevom zakupca
    [2026-03-04] Pokupljena kirija od zakupca 2500e
    [2026-04-02] Obavesten za placanje rente za april
    [2026-04-06] Placena renta za april 2.500e
    [2026-05-04] Placena renta za maj 2.500e
    [2026-05-12] Ivan nas je kontaktirao da opet ne radi klima, obzirom da se javlja isti problem posle manje od godinu dana, kontaktirale smo upravnika, ali smo dobile odgovor da ne moze nista da uradi. Obzirom da je bio petak, nismo mogli da pronadjemo majstora, a on je hteo odmah da se resi pa je sam organizovao majstore. Popravka je iznosila 530 eur, s tim sto je Ivan rekao da ce dati 200 eur. Sve slike i izvestaj se nalaze u folderu popravki.
    [2026-06-03] Sa zakupcem postignut dogovor da ce se troskovi za popravku klime koja je iznosila 530 eur podeliti na pola, tako da je polovina odbijena od rente -> Sonuç: Zakupac je platio rentu u iznosu od 2.232,5 eur
    [2026-07-02] Placena renta za jul  2.500 eur
    [2026-08-06] Placena renta za avgust 2.500 eur
    [2026-09-01] Placena renta za septembar 2.500 eur
    [2026-10-02] Placena renta za oktobar 2.500 eur', 1, now()
    ) ON CONFLICT (id) DO UPDATE SET
        tenant_name = EXCLUDED.tenant_name,
        tenant_phone = EXCLUDED.tenant_phone,
        invitee_email = EXCLUDED.invitee_email,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        monthly_rent = EXCLUDED.monthly_rent,
        tenant_notes = EXCLUDED.tenant_notes;

    INSERT INTO public.contracts (
        id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
        token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
        status, expenses_config, tenant_notes, due_day, created_at
    ) VALUES (
        '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', '795db987-07d2-515b-84cd-1656f271953d', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'EKO SERBIA AD', NULL, NULL,
        '66a67edf69465afa854c41b7c4d53640', '2025-11-01', '2027-10-31', 1650.0, 1650.0, 'EUR', 'EUR',
        'active', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Internet/TV", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Parking", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, 'Orijinal Kontrat: 2025-11-01 - 2027-10-31.
    --- Dnevnik Događaja ---
    [2025-10-02] Za 9.1 West kulu nam je ostao jedan ceo depozit od bivseg stanara I od tog iznosa treba da odbijemo 60 eur za ciscenje i odbicemo mu sve dane u oktobru dok je stan prazan, taj presek cemo uraditi na kraju meseca jer ne znam od kog datuma cemo izdati stan (nemamo jos uvek nove stanare) -> Sonuç: 01.10.2025 Zakupcu je od depozita u iznosu od 1800 eur odbijeno 840 eur za racune za jul, avgust i septembar, vraceno mu je 960 eur. Jos jedan depozit u iznosu od 1800 eur ostao je kod nas
    9.1 Julski racuni u iznosu od 36.186 rsd naplaceno od depozita
    9.1 Nisu stigli svi racuni za avgust (Form focus) zakupcu izracunato prosecno 36.000 i naplacano od depozita
    9.1 Nisu stigli svi racuni za septembar (Form focus) zakupcu izracunato prosecno 36.000 i naplacano od depozita
    Imao pretplatu 84 eur, (bila je 105 eur, ali je odbijeno za karticu 21 eur)
    Renta za oktobar odbijena zakupcu od depozita, a računi za oktobar su išli na teret vlasnika. U toku oktobra meseca u stanu je boravio Luka advokat
    Proveriti da li je Jovana fakturisala rentu za decembar i račune za novembar novom zakupcu Eko Srbija
    [2026-04-02] Jovana mailom potvrdila da je placena renta za mart 27.03.2026.
    [2026-04-17] Jovana mailom potvrdila da je placena renta za april 15.04.2026. kao i da su uplatili prefakturisane troskove za:
    decembar 2025 - 44.490,27 rsd
    januar 2026 - 47.727,03 rsd
    [2026-05-14] Jovana mailom potvrdila rentu za maj da je placena i racuni za februar
    [2026-06-17] Jovana mailom potvrdila da je placena renta za jun, kao i racuni za mart i april
    [2026-07-30] Jovana mailom potvrdila da je placena renta za jul
    [2026-08-04] Jovana mailom potvrdila da je placena renta za avgust
    [2026-09-07] Jovana mailom potvrdila da je placena renta za sept', 1, now()
    ) ON CONFLICT (id) DO UPDATE SET
        tenant_name = EXCLUDED.tenant_name,
        tenant_phone = EXCLUDED.tenant_phone,
        invitee_email = EXCLUDED.invitee_email,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        monthly_rent = EXCLUDED.monthly_rent,
        tenant_notes = EXCLUDED.tenant_notes;

    INSERT INTO public.contracts (
        id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
        token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
        status, expenses_config, tenant_notes, due_day, created_at
    ) VALUES (
        'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', '992ab199-2589-5896-816a-963caadd041e', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', NULL, NULL, NULL,
        'bf569289efa7581796292ab428905662', '2025-04-08', '2027-03-31', 2000.0, 2000.0, 'EUR', 'EUR',
        'active', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Parking", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, 'Orijinal Kontrat: 2024-04-08 - 2027-03-31.
    --- Dnevnik Događaja ---
    [2025-08-12] Od iznosa 39.750 koji su zakupci bili duzni da plate za komunalije za jun, odbijen je iznos od 10.500 za Ikea policu u vesernici, tako da je placeno 250 eur
    [2025-08-12] Od iznosa od 150 eur koje je preuzeto od zakupca placeno Jovici stolaru, izrada i ugradnja ogledala u hodniku u iznosu od 150 eur, za isplatu Jovani 100 eur
    [2025-08-15] Prilikom ugradnje ogledala je pomeren prekidac za svetlo i sad im ne radi svetlo u hodniku
    [2025-08-15] Treba da se kupi i ugradi daljinsko zvonce. Sitno curenje u lavabou,popustio silikon. Zamena cevi aspiratora. Aluminijumsko fleksibilno crevo treba da se zameni. Aspirator je na filter i nema uzlaz u ventilaciju. Zele da im se zameni crevo jer se oseca. Makaze na prozoru u spavacoj sobi onemogucavaju da se zatvori. -> Sonuç: Kupio je i ugradio i popravio je svetlo u hodniku usled toga sto je skinuto ogledalo i zalepljeno
    [2025-08-15] Dodatne police u garderoberu. -> Sonuç: Ugradnja polica
    [2025-10-27] Zakupac predao iznos od 1000 eur za racune za avgust i septembar, ima pretplatu 20 eur. Za klimatizaciju naplacen iznos za avgust 21.000rsd umest 10.430 rsd -> Sonuç: Ima dug za avgust i septembar 82,58 eura
    [2025-12-25] Zakupac predao iznos od 900 eura za račune za oktobar i novembar -> Sonuç: Duguje još 23 eura. Ukupan dug za avgust-novembar je 105 eura, dogvoreno da se to odbije za stolice koje će oni kupiti
    [2026-02-24] Zakupac je predao iznos od 520e, za racune za decembar i dug od 83+23e
    [2026-03-09] PROVERENO JOS JEDNOM SA Jovanom, renta je placena do 31.03.2026. Poslati im upit do kada ostaju u stanu i obavestiti ih o placanju
    [2026-03-11] Ksenija platila račune za januar 350 EUR -> Sonuç: DUGUJE JOŠ 17 EURA
    [2026-03-30] Poslata oba aneksa, kao i  iznos za rentu i račune koji trebaju da plate
    [2026-04-01] Poslata poruka kada im odgovara, rekla je Ksenija da ce za vikend pogledati anekse
    [2026-04-02] Ksenija slikala račun koji je domar dao zbog zamene gumice ispod sudopere, i trazila majstora za vrata od kupatila
    [2026-04-09] Ksenija bila u kancu, donela potpisane anekse, 2000e + 400e za racune
    [2026-04-21] Pozvano je više majstora za vrata od kupatila, zabrali smo najpovoljniju opciju, dogovor je da se odradi račun na firmu i da se popravka odradi danas
    [2026-04-23] Prethodni majstor koji je trebao da nam popravi bravu je otkazao, tako da smo pozvali drugog, otisao je i zamenio bravu -> Sonuç: 8000 dinara zamena i popravka brave, racun na firmu
    [2026-04-29] Struja za mart nije stigla, stavljen iznos kao za februar
    [2026-05-05] Placeni racuni za mart i renta za maj -> Sonuç: 2000eur za rentu + 400 eur za racune
    [2026-05-07] Struja za mart je stigla, promenjen je iznos u tabeli, duguje 600 dinara, naplatiti sledeceg meseca to dugovanje
    [2026-06-02] Placena renta za jun 2000 eur + racuni za april 450 eur -> Sonuç: Dala 600 din dug za struju, ostaje joj 20e za sledeci mesec pretplate
    [2026-07-06] Placena renta za jul 2000 eur + racuni za maj 380 eur ( obzirom da ima pretplatu 20e racuni su 360) -> Sonuç: Ksenija dala 400 eur za racune umesto 360, ostaje 40 eur za sledeci mesec
    [2026-08-11] Placena renta za avgust 2000 eur + racuni za maj 350 eur -> Sonuç: Ksenija dala 350 eur jer je imala pretplatu 40 eur
    [2026-09-10] Placena renta za septembar 2000 eur + racuni za jul 442 eur -> Sonuç: Jovani dato 490 eur za racune, bio je dug od 40 eur
    [2026-10-13] Placena renta za oktobar 2000 eur + racuni za avgust 500 eur + 2000 din', 1, now()
    ) ON CONFLICT (id) DO UPDATE SET
        tenant_name = EXCLUDED.tenant_name,
        tenant_phone = EXCLUDED.tenant_phone,
        invitee_email = EXCLUDED.invitee_email,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        monthly_rent = EXCLUDED.monthly_rent,
        tenant_notes = EXCLUDED.tenant_notes;

    INSERT INTO public.contracts (
        id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
        token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
        status, expenses_config, tenant_notes, due_day, created_at
    ) VALUES (
        '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'Marko Nikollić', NULL, NULL,
        'ed6ff22d73c75b87ac6c09a0889576b5', '2025-10-01', '2026-09-30', 2500.0, 2500.0, 'EUR', 'EUR',
        'active', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Parking", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, 'Orijinal Kontrat: 2025-10-01 - 2026-09-30.
    --- Dnevnik Događaja ---
    [2025-05-27] Stanarka je pre par dana prijavila da joj ne radi usisivac,takodje i da joj ne radi prekidač za bojler -> Sonuç: Angažovali smo električara i kvar u vezi sa napajanjem električne energije i prekidačem je uspešno otklonjen. Usisivač je odnet na servis i popravljen je.
    [2025-10-20] Margarita prethodni zakupac, ostavila je avanso iznos za racune za septembar 2025 koji u tom trenutnu jos nisu dospeli, avans je iznosio 23.100 rsd a racuni su dosli u iznosu od 24.096 -> Sonuç: Internet sbb proveriti da li je placen za septembar
    [2025-09-24] Prilikom obilaska stana nakon izlaska zakupca lavabo u jednom od kupatila bio je naprso, a sada ta pukotina deluje jos gore, pored toga, ormaric lavaboa je potpuno raskliman I truo od vode - Potrebno je zameniti i lavabo i ormaric lavaboa (pronasla sam u Ikei komplet za 43.000 rsd, i pretpostavljam da su ruke jos oko 100 eur)
    Police u singl decijoj sobi su potpuno rasklimane, I kada se nesto stavi na njih, krive se i deluju da ce da padnu i to bi trebao neko da pricvrsti sa dodatnim drzacima -> Sonuç: (cena novog TV/a 70.000 rsd plus nosac 8000 rsd, plus ruke vrvt oko 50 eur)
    [2025-10-02] Od zakupca je juce primljen iznos od 2500 eur za rentu za oktobar. -> Sonuç: Jovana bi trebala da preda iznos od 130 eur za usluge majstora koji je dopremio iz Lesnine i zamenio lavabo i ormaric u kupatilu, zalepio lajsnu na tv zidu u dnevnoj sobi, izneo sa terase velike saksije sa zemljom, i pricvrstio police u sobi. - placeno
    Kupljena su 4 nova jastučeta za garnituru u dnevnoj sobi
    [2025-12-05] Primljen iznos od 2500 za rentu i 22.000 za racune za oktobar
    [2026-02-11] Stanar prijavio da mu ne radi prekidač za bojler i prekidač za svetlo u jednom kupatilu. Takođe je prijavio da mu ne radi smart sistem na televizoru ni wi-fi u spavaćoj sobi -> Sonuç: Mora da se angažuje električar
    [2026-03-06] Primljen iznos od 292.500 rsd za rentu za mart
    [2026-03-20] Primljen iznos od 83.500 rsd za racune za januar i februar -> Sonuç: 7.200 dinara za mts uzeto, zamolio je da platimo
    [2026-04-02] Poslata poruka za kiriju za april
    [2026-04-06] Placena kirija za april -> Sonuç: 292.500 primljeno
    [2026-04-24] Elektricar je bio juce, promenio je prekidac, ustanovio je da bojler ne radi, a internet na tv-u ce popraviti -> Sonuç: Danas ce otici majstor za bojler da ga popravi, cena iznosi 12.000 dinara, Darko ce platiti pa cemo mu odbiti taj iznos kada bude davao za troskove
    [2026-05-04] Pavle elektricar popravio prekidač, svetlo (u kupatilu) i resio problem sa TV-om u spavaćoj sobi (sproveo Lan kabal do TV-a) pa sad imaju internet -> Sonuç: Iznos popravki je iznosio 8.000 dinara
    [2026-05-06] Primljen iznos od 314.300 dinara, renta za maj i racuni za mart -> Sonuç: Obzirom da je platio sam popravku za bojler naplaceno mu je 12 hiljada manje
    [2026-06-19] Prekidac ne radi na kupatilu ponovo, pozvan elektricar otici ce u ponedeljak da popravi
    [2026-06-22] Popravljen prekidac, popravka je iznosila 6.800 dinara, uplaticemo Pavlu na racun, pa ce Jovana da nam da novac
    [2026-07-07] Pokupljena renta za jul 2.500 eur + racuni za maj -> Sonuç: Ukupno 323.800 dinara uzeto
    [2026-08-04] Pokupljena renta za avgust 2.500 eur + racuni za jun -> Sonuç: Ukupno 292.500 din za rentu i 24.700 din za racune
    [2026-08-18] Krevet iz A bloka prebacen u ostavu 081 i 088 u Rivieru -> Sonuç: Odnesena i nova garnitura za terasu i postavljena, ti troskovi su iznosili 200 eur za prenos iz emecete u stan bastenski namestaj, nakon toga kreveti iz a bloka u rivieru, bastenski set i jastuci su iznosili 29.680 dinara
    [2026-09-08] Pokupljena renta za septembar + racuni za jul -> Sonuç: 320.000 dinara
    [2026-10-14] Pokupljena renta za oktobar + racuni za avgust', 1, now()
    ) ON CONFLICT (id) DO UPDATE SET
        tenant_name = EXCLUDED.tenant_name,
        tenant_phone = EXCLUDED.tenant_phone,
        invitee_email = EXCLUDED.invitee_email,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        monthly_rent = EXCLUDED.monthly_rent,
        tenant_notes = EXCLUDED.tenant_notes;

    INSERT INTO public.contracts (
        id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
        token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
        status, expenses_config, tenant_notes, due_day, created_at
    ) VALUES (
        'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', '6308167e-af32-53bb-9c22-df5efa478fa1', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'Sigitov Denis, Alena Safronova', '+79639463752', NULL,
        'e36067860297574f9d66ae10f4f7e735', '2026-06-24', '2027-06-23', 2000.0, 2400.0, 'EUR', 'EUR',
        'active', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Parking (Kalan)", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity (Kalan)", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance (Kalan)", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Parking", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Infostan (Kalan)", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, '--- Dnevnik Događaja ---
    [2025-06-23] Zakljucen ugovor o zakupu. Uplaceno: depozit 2300 eur i prva zakupnina 2300
    [2025-08-04] Zakupac prijavio da ne radi usisivac. -> Sonuç: Uzet usisivac iz A 5.17 i odnet u C 7.28, a pokvareni usisivac kod Natase u gepeku, treba da se nosi na servis
    [2025-08-04] Zakupac istakao zahtev da zeli draperije u obe spavace sobe -> Sonuç: Biljana odobrila, narucene su draperije kod Gabrijele dana 06.08
    [2025-08-05] Zakupac obavesten da treba da plati 64 eur za komunalije za deo juna
    [2025-09-25] Zakupac trazio instalaciju i kupovinu TV za spavacu sobu
    [2025-10-02] Poručen novi televizor - 44.000 din + 2.000 din dostava
    [2025-10-20] Namontiran TV, Radmila sama kupila nosač, cena montaže 4.500 dinara -> Sonuç: Nije trazila refundaciju za nosac za TV
    [2025-10-27] Jovana potvrdila: 2300 eur renta do 22.11 (novembar) + 36500 rsd za racune za septembar (racuni su 34.490,11 rsd) imala dug od 25 eur, sada duguje jos 915 rsd.
    [2025-11-25] Platili rentu za decembar - 2.300 EUR i dali 300 EUR za račune za oktobar -> Sonuç: Dali još 1000 dinara za dug iz prethodnog meseca
    Otkazali ugovor o zakupu. Iz depozita odbijeno za račune za novembar i decembar, za čišćenje stana 150 eura sanacija parketa 100 eura i renta za januar 2300 eura
    [2026-02-11] Stanarka prijavila curenje bojlera. Takođe je prijavila da joj ne radi mali bojler i da je u pitanju utičnica. -> Sonuç: Curenje je sanirano, pozvali smo izvođača radova jer je zgrada i dalje u garanciji. Za bojler je angažovan izvođač koji će ovih dana to da reši.
    Stanarka je izbacila i predala Natasi, sve jastuke, jorgane i svu posteljinu iz stana, i to ce biti smesteno u ostavu stana 1607 BW Aqua u plavim Ikea torbama. Takodje je izbacila usisivac, ali ga nije predala nama, potrebno je da ga ona vrati prilikom isteka ugovora.
    [2026-03-25] Stanarka je obavestena o iznosu koji treba da isplati za racune za februar
    [2026-03-30] Sara je rekla da će danas ili sutra da ostavi novac za račune
    [2026-04-01] Preuzet iznos za racune za februar 500 EUR + 2.000 RSD
    [2026-04-21] Nataša je uzela usisivač od Sare jer ga ona ne koristi, pa je odnela Ani u Terraces 104 jer se njen pokvario
    [2026-05-06] Preuzet iznos za racune za mart 53.500 dinara
    [2026-06-02] Sara preuzela iznos od 16.800 eur za rente koje je platila unapred obzirom da je raskinula ugovor o zakupu -> Sonuç: RACUNI ZA APRIL PLACENI OD DEPOZITA KOJI SE ZADRZAVA ZA POKRIVANJE TROSKOVA
    [2026-06-16] Cistacica je bila i detaljno ocistil stan, kao i covek za dubinsko pranje namestaja
    [2026-06-24] Useljeni novi stanari, placena renta za period od 24.06.-23.06.2026.
    [2026-06-28] Odnet novim stanarima jos jedan kljuc sa tagom, sada su kod njih 3 kljuca, dva sa tagom i jedan bez
    [2026-07-29] Placena renta za avgust i septembar 4.000 eur -> Sonuç: Za period od 24.07.-23.09.2026.
    [2026-08-28] Placeni racuni za jul, dato 320 eur i 200 din
    [2026-09-22] Posteljine koje su bile u firmi u dve Ikea plavim kesama su prebacene u ostavu broj 081 u Rivieri
    [2026-09-25] Placena renta za oktobar i novembar ( 24.09.-23.11.) kao i racuni za avgust u iznosu od 278 eur -> Sonuç: Takodje platili su racune za period od 7 dana u junu kada su se uselili ( 70 eura )', 1, now()
    ) ON CONFLICT (id) DO UPDATE SET
        tenant_name = EXCLUDED.tenant_name,
        tenant_phone = EXCLUDED.tenant_phone,
        invitee_email = EXCLUDED.invitee_email,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        monthly_rent = EXCLUDED.monthly_rent,
        tenant_notes = EXCLUDED.tenant_notes;

    INSERT INTO public.contracts (
        id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
        token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
        status, expenses_config, tenant_notes, due_day, created_at
    ) VALUES (
        'cb25757e-2763-5330-8354-582458caddfe', '47013784-dd68-567f-942a-90c43141820a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'Rade Jerinic', '+634124120', NULL,
        'e82e2f7bda1c5dee96830f739f2088a2', '2025-07-22', '2027-07-21', 3200.0, 3200.0, 'EUR', 'EUR',
        'active', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Parking", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, 'Orijinal Kontrat: 2025-07-22 - 2027-07-21.
    --- Dnevnik Događaja ---
    [2025-06-14] Uselili su se short term zakupci na period od 14.06-01.07 i platili iznos od 3400 eur
    [2025-07-22] Potpisan ugovor o zakupu. Zakupac uplatio depozit u iznosu od 3200 eur, 1600 eur za period 22.07.-22.08 (kirija sa 50% popusta) i 930 eur za period od 23.08-31.08. (deo kirije za 9 dana avgusta po punoj ceni zakupnine srazmerno broju dana)
    [2025-07-23] Izneti su singl kreveti iz sobe i preneti u ostavu br.12 na -1, u B kulu BW Residences
    [2025-07-23] Gabrijela nas je obavestila da masina za sudje izlazi iz lezista i da treba da se pricvrsti, takodje i da u tom stanu nema usisivaca.
    [2025-08-05] Zakupac istakao zahtev da o svom trosku skine luster iz dnevne sobe i da stavi svoj, rekao da ce pri izlasku iz stana da vrati u prvobitno stanje
    [2025-10-06] Zakupac dao tri mesečne kirije unapred, za oktobar, novembar i decembar 2025. god. -> Sonuç: Platio racune za avgust (racuni iznose 40.075,79 rsd / 343 eur) tako da zakupac ima pretplatu 57 eur + stara pretplata 14 eur
    [2025-12-19] Dao novac za račune za septembar, oktobar i novembar -> Sonuç: Ukupan iznos računa 135.8800 din, on je dao 140.000 din tako da ima pretplatu 4.120 din
    6700 renta jan i feb i 300 e avans za račune
    [2026-02-27] Zakupac dao rentu za mart 3200 e i novac za racune za januar -> Sonuç: Dao 50e vise tako da ima pretplatu + pretplata iz prethodnog perioda 331e
    [2026-04-02] Poslata poruka za placanje rente za april i racune za februar
    [2026-04-06] Placena kirija za april 3200 + racuni za februar 700e -> Sonuç: Dao 2.140 dinara vise + pretplata iz prethodnog perioda 381e
    [2026-05-04] Placena kirija za maj 3200 + racuni za mart 74.000 dinara
    [2026-06-03] Placena kirija za maj 3200 + racuni za mart 600 eur + 2.000 dinara -> Sonuç: Dao 1000 dinara vise
    [2026-06-09] Rade se pozalio da ne radi interfon, majstor ce doci da popravi jer je zgrada u garanciji
    [2026-07-01] Rade platio rentu za jul 3.200 eur + dao novac za racune za maj 570 eur
    [2026-08-04] Rade platio rentu za avgust, septembar i oktobar 9.600 eur + novac za racune za jun 470 eur
    [2026-09-10] Placeni racuni za jul u iznosu od 56.200 dinara
    [2026-10-07] Placeni racuni za avgust 500 eur + 1000 dinara', 1, now()
    ) ON CONFLICT (id) DO UPDATE SET
        tenant_name = EXCLUDED.tenant_name,
        tenant_phone = EXCLUDED.tenant_phone,
        invitee_email = EXCLUDED.invitee_email,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        monthly_rent = EXCLUDED.monthly_rent,
        tenant_notes = EXCLUDED.tenant_notes;

    INSERT INTO public.contracts (
        id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
        token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
        status, expenses_config, tenant_notes, due_day, created_at
    ) VALUES (
        '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', '64ba78b5-a1b9-5157-9070-5481c640b124', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'Branko Pavlovic', '+3816653440520', NULL,
        '843d16503c52551a878f7ced320b331b', '2025-06-01', '2027-05-31', 1200.0, 2400.0, 'EUR', 'EUR',
        'active', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Parking", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, 'Orijinal Kontrat: 2025-06-01 - 2027-05-31.
    --- Dnevnik Događaja ---
    [2025-06-02] Zakupac je tražio dve komode pored kreveta,prostirke za kupatilo i kantu u kupatilu. Trazio je cediljku za tanjire i escajg,takodje stalak za ubrus,slanik i krpe za kuhinju. Prostirke ispred stana i na ulazu u stan je tražio. Za dnevni boravak želi komodu. -> Sonuç: Nabavili smo nocne stocice.
    zakupac u januaru 2026 godine, platio zakup za period 25.12.2025 do 24.01.2026 i platio racune za novembar 21.000 rsd
    [2026-03-11] Branko dao za račune za januar 26.000 dinara i rentu za mart 1.400 dolara (1.200 eura) -> Sonuç: Predato Jovani
    [2026-03-16] Zakupac trazi snizenje cene rente sa 1200 na 1000 eur uz obrazlozenje da je nasao jeftiniji stan. Poslat mail Jovani za konsultaciju
    [2026-03-27] Zakupac platio rentu 1000 EUR + racune za februar 27.500 dinara -> Sonuç: Predato Jovani
    [2026-03-30] Odradjen aneks za smanjenje rente sa 1200 na 1000, dati mu da potpise kada se sledeci put budemo nalazili za novac
    [2026-04-26] Branko je rekao da ce u sredu doneti novac jer je na putu
    [2026-04-28] Placena renta za period od 25.04. - 24.05.2026 -> Sonuç: 1000 eur renta plus 25.530 dinara racuni za mart
    [2026-05-29] Placena renta za period od 25.05. - 24.06.2026 -> Sonuç: 1000 eur renta + 24.800 dinara racuni za april
    [2026-05-29] Zakupac je zatrazio komodu i televizor za spavacu sobu
    [2026-06-24] Porucena komoda iz jyska kao i televizor za spavacu sobu -> Sonuç: Poruceno je sa kartice Asserie tako da je automatski placeno
    [2026-06-29] Preuzeta renta za period od 25.06.-24.07 100 eur + novac za racune 24.800 din -> Sonuç: Za racune je dao 2.500 manje
    [2026-07-08] Nakon nestanka struje u stanu, rerna nije radila, danas je bio ovlasceni serviser i popravio rernu -> Sonuç: Obzirom da je u garanciji rerna, nije bilo naplate
    [2026-08-11] Preuzeta renta za period od 25.07.-24.08 -> Sonuç: 1000 eur renta + 24.600 din ( uracunat i dug od 2.500 din )
    [2026-09-08] Preuzeta renta za period 25.08.-24.09. -> Sonuç: 1000 eur renta + 21.300 racuni jul
    [2026-10-08] Preuzeta renta za period od 25.09.-24.10. -> Sonuç: 1000 eur renta + 21.00 dinara racuni avgust', 1, now()
    ) ON CONFLICT (id) DO UPDATE SET
        tenant_name = EXCLUDED.tenant_name,
        tenant_phone = EXCLUDED.tenant_phone,
        invitee_email = EXCLUDED.invitee_email,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        monthly_rent = EXCLUDED.monthly_rent,
        tenant_notes = EXCLUDED.tenant_notes;

    INSERT INTO public.contracts (
        id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
        token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
        status, expenses_config, tenant_notes, due_day, created_at
    ) VALUES (
        'e117504d-ff5b-5390-987e-e27e885862c5', 'a9a4d27b-b3d3-5572-a0f4-0ab22a7b32d6', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'Slavica Jovanovic', '+6072222220', 'slavica.jovanovic.nikolic@gmail.com',
        'a6e88aabbab85348aa2eacdc07fb039f', '2026-04-04', '2027-04-03', 2000.0, 3000.0, 'EUR', 'EUR',
        'active', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, '--- Dnevnik Događaja ---
    [2025-06-10] Zakljucen ugovor o zakupu. Uplaceno: depozit 2200 eur, 410 eur avansno za racune i prva zakupnina za deo juna 1450 eur 10.06.-30.06
    [2025-06-10] Zakupac je istakao sledeće primedbe: Uklanjanje tapeta. Zatvoriti uticnice u glavnoj spavacoj sobi. Double bed u gostinjskoj sobi i manji TV u istoj sobi. Na ulazu u ormaru fale usporivači. Push sistem za garderober fali u glavnoj spavacoj sobi i usporivaci. Problem sa internetom. Namestaj za terasu. Pribor za jelo i kuhinjska oprema. Takodje fale peškiri,ogrtači,pegla i usisivač. Tražila je sef. -> Sonuç: Obaveštena je da zahtev za internet mora sama da podnese. Kupljen joj je sef. Nabavili smo joj double bed za gostinjsku sobu. Nabavili smo joj TV za gostinjsku sobu. Nabavili smo peglu.
    [2025-06-11] Zakupac je istakao sledeće primedbe:Nema usporivač ispod sudopere. Orman na ulazu udara. U gostinjskoj sobi vire šrafovi. Nema stoper za vrata u spavaćoj sobi. Fali kanta za djubre,sušač za veš,aparat za kafu i toster. Zakupac je trazio otvorene police za cipele u master sobi pored ormana. -> Sonuç: Nameštena joj je kanta i ugradjena joj je u gostinjskoj sobi u ormanu. Električar je došao za prekidače i ugradio usporivač na ulazu. Isporucene su joj otvorene police za cipele u master sobi. Nabavili smo zakupcu toster,aparat za kafu.                                                                                                             •        Toster okvirna cena 100 eur 
    •        Kafe aparat okvirna cena 100 eur 
    •        Žica-sušač za veš okvirna cena 50 eur 
    •        Sef - okvirna cena 120 eur 
    •        Mali TV za gostinsku sobu (okvirno 300 eur)
    [2025-11-14] Milica dala rentu za novembar, dala je 2.200 EUR, kirija joj je 1.150 EUR -> Sonuç: Ostala dužna da plati račune za septembar u iznosu od 27.906,89 din (ali ima pretplatu 35 EUR)
    Milica je donela 25.02. iznos od 79.100 za racune za novembar i decembar 2025
    Duguje racune za januar i februar kao i rentu za januar i februar 2026 -> Sonuç: Ukupno 4300 eur plus racuni januar Дин. 59,821.84 plus za februar
    Opomene su isle svaki drugi dan pocev od 10.01.2026
    Ukupno dugovanje pristiglo do sad 4300 eur plus racuni za januar
    [2026-03-17] Milica zvala i obavestila da ce isplatiti dug u petak 20.03.2026
    [2026-04-04] Usao novi zakupac, dala prvu rentu u iznosu od 2000 EUR + 3000 EUR depozit
    [2026-04-29] Slavica je zamolila da se dubinski opere nameštaj u dnevnoj sobi, kao i tepisi jer su dosta pokupili miris cigara od prošlog zakupca. -> Sonuç: Dubinsko pranje nameštaja je odradjeno, iznosilo je 4.000 dinara i plaćeno je u kešu. Tepisi su takodje odneti, za njih je odradjen predračun, iznos je 10.206 dinara, poslato je Jovani da plati
    [2026-05-06] Preuzeta renta za 3 meseca unapred, za maj, jun i jul -> Sonuç: 6.000 eur
    [2026-05-08] Slavici ostavljen kljuc od stana na Terraces-u, zatrazila je jos jedan jer joj je dat samo jedan kljuc
    [2026-06-03] Slavica uplatila 34.000 za racune za april
    [2026-07-03] Placeni racuni za maj u iznosu od 40.250 dinara
    [2026-08-06] Placena renta za avgust 2.000 eur + racuni za jun u iznosu od 31.000 din
    [2026-09-08] Placena renta za septembar 2.000 eur + racuni za jul u iznosu od 32.400 rsd
    [2026-10-13] Placena renta za oktobar 2.000 eur + racuni za avgust 32.000 + 5 eur', 1, now()
    ) ON CONFLICT (id) DO UPDATE SET
        tenant_name = EXCLUDED.tenant_name,
        tenant_phone = EXCLUDED.tenant_phone,
        invitee_email = EXCLUDED.invitee_email,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        monthly_rent = EXCLUDED.monthly_rent,
        tenant_notes = EXCLUDED.tenant_notes;

    INSERT INTO public.contracts (
        id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
        token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
        status, expenses_config, tenant_notes, due_day, created_at
    ) VALUES (
        '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'Maja Vukovic', '+381696824200', 'bizzupmentorship@gmailcom',
        '59623841a9245efdbff87a7b160effee', '2025-09-02', '2027-09-01', 2450.0, 3675.0, 'EUR', 'EUR',
        'active', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Parking", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, 'Orijinal Kontrat: 2025-09-02 - 2027-09-01.
    --- Dnevnik Događaja ---
    [2025-11-21] Platila račune za oktobar - dala 42.000 dinara
    [2025-12-12] Platila rentu za decembar 2.450 EUR i dala još 250 EUR više - ukupno dala 2.700 EUR -> Sonuç: 250 EUR ostaviti pa platiti sledeće račune
    [2026-01-09] Platila rentu za januar i račune za novembar, u to ulazi i 250 EUR od pretplate od prethodnog meseca -> Sonuç: Ima pretplatu nekih 13 EUR
    [2026-02-11] Platila rentu za januar i račune za decembar -> Sonuç: Nije dala tačan iznos, fali 212 eura ili 25.000 dinara. Dala je 149.500. dinara i 505 eura
    [2026-02-18] Maja dala 212 eura koji su falili
    [2026-03-06] Platila rentu za mart 2.450 EUR i dala 870 eur za racune -> Sonuç: Dala je 90e vise tako da je u pretplati
    [2026-04-06] Placena renta za april 2.450 EUR i dala 70.000 dinara za racune -> Sonuç: Pretplata od proslog puta 90e
    [2026-05-06] Placena renta za maj 2.450 EUR + 600 eur za racune za mart
    [2026-06-05] Placena renta za jun + racuni za april -> Sonuç: Dato je 1000 eur + 229.500 dinara, ja sam iz pretplate dodala 20 eur jer su dali toliko manje za racune, sada im ostaje pretplata od 70 eur
    [2026-07-08] Placena renta za jul + racuni za maj -> Sonuç: Dato je 2.350  eur + 72000 dinara, dodato 20 eur iz pretplate
    [2026-08-07] Placena renta za avgust  + racuni za jun -> Sonuç: 1.000 eur + 170.000 din renta + 53.520 din za racune
    [2026-09-09] Placena renta za septembar + racuni za jul -> Sonuç: 2.450 eur + 55.000 din
    [2026-10-13] Placena renta za oktobar + racuni za avgust -> Sonuç: 2450 eur + 56000 dinara', 1, now()
    ) ON CONFLICT (id) DO UPDATE SET
        tenant_name = EXCLUDED.tenant_name,
        tenant_phone = EXCLUDED.tenant_phone,
        invitee_email = EXCLUDED.invitee_email,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        monthly_rent = EXCLUDED.monthly_rent,
        tenant_notes = EXCLUDED.tenant_notes;

    INSERT INTO public.contracts (
        id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
        token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
        status, expenses_config, tenant_notes, due_day, created_at
    ) VALUES (
        '1bdae1ee-7fb8-55c9-8843-fabb14d70478', 'cbb8caa3-60d2-5462-b18d-deb10d72e925', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'Marco Gajic', NULL, NULL,
        '965b1c5e10fe5d8cbcaf7d33170bf451', '2025-10-01', '2026-09-30', 4500.0, 9000.0, 'EUR', 'EUR',
        'active', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, 'Orijinal Kontrat: 2025-10-01 - 2026-09-30.
    --- Dnevnik Događaja ---
    Prozori u podrumu ne rade dobro, ulazi voda kada je kiša. Vlaga u spavaćoj sobi. Problem sa bazenom- smanjeju se nivo vode.
    Zakupac je 1.09.2025. nagovestio da izlazi zaključno sa 30.09. 2025.
    Novi zakupac je zatražio ugradnju i zidanje djakuzija u podrumu u iznosu od 10.000 EUR. Pokrivka za bazen 1.800 EUR u našem trošku.
    [2025-10-02] Zakupci su predali iznos od 9000 eur za depozit (dve kirije), a u subotu ili nedelju radimo primopredaju sa njima kada ce mi predati I iznos za prvu rentu (treba da im se preracuna za period od 05.10 pa do kraja meseca, po mom proracunu to je 3920 EUR) -> Sonuç: Za Sremcicu treba Jovana da preda iznos od 100 eur koji bi trebalo da odbije od depozita prethodnog zakupca za čišćenje, osim toga od tog depozita treba da odbijemo I iznos za racune kada dobijemo od Nikole Korde taj iznos. Za hemiju za ciscenje donela racun 1800 dinara, taj novac mi je vec dala. Za Sremcicu mi je Jovana predala iznos od 1722 eur koji sam predala bazendziji za pokrivku za bazen (priznanica u prilogu, a original cu preuzeti kad ga vidim)
    [2025-11-04] Išlo se u Sremčicu da se uzme renta. Danas se takođe popravljaju radijatori u kupatilima i garaži i podešava se struja, tj majstori i električari podešavaju da struja i wi fi rade u svim sobama
    Proveriti da li je Nikola kupio poštansko sanduče za Sremčicu
    [2026-01-12] Marco doneo rentu za januar 4.500 EUR
    [2026-02-18] Dali rentu za februar - 4.500 EUR
    [2026-03-09] Poslat im je podsetnik za placanje rente i uputstvo za samoocitavanje brojila.
    [2026-03-16] Placena renta za mart 4.500 EUR
    [2026-04-02] Poslat mail za placanje rente
    [2026-04-06] Poslata poruka na wa, nije odgovorio, nakon toga se Natasa cula sa Markom, rekao je u cetvrtak da se vidimo za rentu
    [2026-05-06] Pokupljena renta za maj u iznosu od 4.500 eur
    [2026-06-05] Pokupljena renta za jun u iznosu od 4.500 eur
    [2026-09-29] Odradjeno kosenje trave i ocupavanje trave i taj trosak je iznosio 150 eur
    [2026-10-01] Novi zakupci dali jedan depozit u iznosu od 3.900 EUR
    [2026-10-02] Dali deo depozita u iznosu od 1.700 EUR i dali kiriju u isnosu od 3.900 EUR', 1, now()
    ) ON CONFLICT (id) DO UPDATE SET
        tenant_name = EXCLUDED.tenant_name,
        tenant_phone = EXCLUDED.tenant_phone,
        invitee_email = EXCLUDED.invitee_email,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        monthly_rent = EXCLUDED.monthly_rent,
        tenant_notes = EXCLUDED.tenant_notes;

    INSERT INTO public.contracts (
        id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
        token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
        status, expenses_config, tenant_notes, due_day, created_at
    ) VALUES (
        'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'Keith Camilleri', NULL, NULL,
        '9e6b25e5356d5cc3b1abe03355b05f48', '2026-01-11', '2026-07-11', 4000.0, 8000.0, 'EUR', 'EUR',
        'active', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Internet/TV", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Parking", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, '--- Dnevnik Događaja ---
    [2026-01-11] Platili rentu za 3 meseca unapred
    [2026-01-15] Plaćeni računi za decembar
    Pre ngo što su se zakupci uselili u stan, organizovano je i plaćeno detaljno čišćenje stana
    [2026-02-16] Zakupci prijavili da im se pokvarila mašina za pranje veša (mašina nije u garanciji više) -> Sonuç: Kvar je prijavljen servisu za popravku mašine
    [2026-02-19] Serviseri su bili da poprave masinu, promenjena je guma i provereno je da masina ne ispusta vodu -> Sonuç: Placeno je na licu mesta 10.000
    [2026-03-10] Pokupljen racun za struju, racun iznosi 4843,22, ali je u pretplati 2814,78
    [2026-03-13] Placeni racuni za februar -> Sonuç: Razmenjeno 750e za racune
    [2026-04-06] Platio rentu jos 3 meseca unapred -> Sonuç: 12.000 EUR
    [2026-04-20] Placeni racuni za mart ( bez struje i mts) u iznosu od 78.918,02 -> Sonuç: Razmenjeno je 690 eur
    [2026-04-21] Stigao je racun za MTS uvecan, zvali smo i dobili povratnu informaciju kako se na jednom racunu nalazi racun i za Hercegovacku i za adresu gde vlasnik zivi
    [2026-05-08] Razmenjeno 100 eur da bi se platio MTS racun -> Sonuç: Ostao kusur 1000 dinara
    [2026-05-21] Razmenjeno je 850 eur od agencijske provizije za racune i placeni svi racuni -> Sonuç: Dobijeno 99.025 dinara, kusur 2.290 dinara
    [2026-06-26] Placeni racuni za maj u iznosu od 88.708,52 dinara', 1, now()
    ) ON CONFLICT (id) DO UPDATE SET
        tenant_name = EXCLUDED.tenant_name,
        tenant_phone = EXCLUDED.tenant_phone,
        invitee_email = EXCLUDED.invitee_email,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        monthly_rent = EXCLUDED.monthly_rent,
        tenant_notes = EXCLUDED.tenant_notes;

    INSERT INTO public.contracts (
        id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
        token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
        status, expenses_config, tenant_notes, due_day, created_at
    ) VALUES (
        'e559b478-f5e8-5117-8bc3-828316fda97d', '500002db-410a-5fc6-b10f-1cdd119ed20a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'Eduard Samofal i Tatiana Morozova', '+381621469404', 'morozovatata2202@yandex.ru',
        '99262d35cf8f5a2e8607fb6210bb2fbc', '2026-06-10', '2027-06-09', 1300.0, 1800.0, 'EUR', 'EUR',
        'active', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity (Kalan)", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance (Kalan)", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Internet/TV", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Internet/TV (Kalan)", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Infostan (Kalan)", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, '--- Dnevnik Događaja ---
    Stan je detaljno sredjen i ociscen, odradjeno je dubinsko ciscenje namestaja, izbacene stvari u tri kutije koje su stavljene u ostavu od Aque 1807. Takodje, postavljen je alarm na ulazna vrata, svi računi su skenirani i prosledjeni Jovani -> Sonuç: Troskovi su iznosili: - 8.000 dinara za iznosenje stvari                          - 3.500 dinara dubinsko ciscenje    - 5.577.30 dinara jastuci i jorgan
    [2026-06-10] Primopredaja kljuceva i useljenje novih zakupaca
    [2026-07-06] Placena renta jul u iznosu od 1.300 eur
    [2026-07-07] Zakupac se pozalio kako prskalice prskaju umesto na povrsinu trave, prskaju po terasi, poslat je mail Beogradu na vodi, kao i Facility pointu, i pozvan je upravnik zgrade, cekamo majstore
    [2026-08-05] Pokupljena renta za avgust, kao i novac za racune za period od 10.06. - 30.06 -> Sonuç: 1300 eur renta + 24400 din za racune
    [2026-09-08] Pokupljena renta za septembar, kao i novac za racune za jul -> Sonuç: 1300 eur + 30.270 din
    [2026-10-07] Pokupljena renta za oktobar i racuni za avgust -> Sonuç: 1300 eur renta + 240 eur racuni', 1, now()
    ) ON CONFLICT (id) DO UPDATE SET
        tenant_name = EXCLUDED.tenant_name,
        tenant_phone = EXCLUDED.tenant_phone,
        invitee_email = EXCLUDED.invitee_email,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        monthly_rent = EXCLUDED.monthly_rent,
        tenant_notes = EXCLUDED.tenant_notes;

    INSERT INTO public.contracts (
        id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
        token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
        status, expenses_config, tenant_notes, due_day, created_at
    ) VALUES (
        'bb6671cf-bf7d-5a27-a63f-479e9d6ae41d', '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'Vasyl Ruzov', NULL, NULL,
        'b387328410b4587581f51579a4d58989', '2026-05-11', '2027-05-10', 2500.0, 3500.0, 'EUR', 'EUR',
        'active', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity (Kalan)", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance (Kalan)", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Internet/TV", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Internet/TV (Kalan)", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Infostan (Kalan)", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, '--- Dnevnik Događaja ---
    [2026-05-10] Novi zakupac je pri ulasku u stan platio depozit u iznosu od 3.500 eur i prvu rentu u iznosu od 2.500 -> Sonuç: Ovu rentu cemo racunati kao rentu za jun, dok je 10.06.2026. platio 1695 eur i to ce biti renta za period od 21 dan u maju tj od 11.05.-31.05.
    [2026-06-10] Platio rentu za period od 21 dan u maju, dao je 200.000 dinara
    Zakupac prijavio problem - ne radi mali bojler i odredjena svetla -> Sonuç: Cekamo da posalje mail sa objasnjenjem kvara
    [2026-07-01] Placena renta za jul 2.500 eur + racuni za maj u iznosu od 29.800 dinara
    [2026-08-03] Placena renta za avgust 2.500 eur + racuni za jun u iznosu od 59.700 dinara -> Sonuç: Takodje dodao je 8.600 za info stan u maju
    [2026-09-02] Placena renta za septembar 2.500 eur + racuni za jul 58.700 dinara
    [2026-10-13] Placena renta za oktobar 2.500 eur + racuni za avgust 60.000 dinara -> Sonuç: 352.200 dinara dato', 1, now()
    ) ON CONFLICT (id) DO UPDATE SET
        tenant_name = EXCLUDED.tenant_name,
        tenant_phone = EXCLUDED.tenant_phone,
        invitee_email = EXCLUDED.invitee_email,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        monthly_rent = EXCLUDED.monthly_rent,
        tenant_notes = EXCLUDED.tenant_notes;

    INSERT INTO public.contracts (
        id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
        token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
        status, expenses_config, tenant_notes, due_day, created_at
    ) VALUES (
        'a253202e-e51d-5f05-b845-45ff2e5cd287', '964b18b7-4c64-54a1-b9ee-35f5ad7df0ba', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'Simone Vuletic da Silva', '+6035830220', NULL,
        'c9c2d8b31a2157e9a6b662ca4fa9ac38', '2026-08-01', '2027-07-31', 2800.0, 2800.0, 'EUR', 'EUR',
        'active', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, '--- Dnevnik Događaja ---
    [2026-08-05] Placena i prva renta i depozit, predato Jovani
    [2026-08-01] Placena renta za septembar i oktobar u iznosu od 5.600 eur', 1, now()
    ) ON CONFLICT (id) DO UPDATE SET
        tenant_name = EXCLUDED.tenant_name,
        tenant_phone = EXCLUDED.tenant_phone,
        invitee_email = EXCLUDED.invitee_email,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        monthly_rent = EXCLUDED.monthly_rent,
        tenant_notes = EXCLUDED.tenant_notes;

    INSERT INTO public.contracts (
        id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
        token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
        status, expenses_config, tenant_notes, due_day, created_at
    ) VALUES (
        'caceed58-63e6-5b4b-a006-e9b4fb669843', 'd97b99c6-9b85-56ba-82fd-d4349b846268', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'Ghter Lizaveta', '+6413759990', NULL,
        '86f9ef156ce555d889b2af0697f74cdb', '2026-08-10', '2027-08-09', 3350.0, 6700.0, 'EUR', 'EUR',
        'active', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, '--- Dnevnik Događaja ---
    [2026-08-05] Od novih zakupaca pokupljen depozit u iznosu od 1.000 eur i predat danas jovani
    [2026-08-11] Preuzet ostatak depozita 5700 eur kao i renta za period od 11.08.-31.08. 2.270 eur -> Sonuç: Dali ukupno 8.100 eur, ostaje pretplata 30 eura
    Masina za susenje iz 303 prebacena u 2301, a iz 2301 u 303
    [2026-09-01] Placena renta za septembar u iznosu od 3500 eur ( dali 3.470 eur i imaju pretplatu 30e od proslog meseca
    [2026-10-01] Placena renta za oktobar u iznosu od 3350 eur -> Sonuç: Otkazali su drugo pm, tako da je sada renta 3.350 eur', 1, now()
    ) ON CONFLICT (id) DO UPDATE SET
        tenant_name = EXCLUDED.tenant_name,
        tenant_phone = EXCLUDED.tenant_phone,
        invitee_email = EXCLUDED.invitee_email,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        monthly_rent = EXCLUDED.monthly_rent,
        tenant_notes = EXCLUDED.tenant_notes;

    INSERT INTO public.contracts (
        id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
        token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
        status, expenses_config, tenant_notes, due_day, created_at
    ) VALUES (
        '8a58ee7b-386f-56b6-8093-cab23000052b', '6c87c83b-3315-5079-8fa3-96b2cf34b920', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'Jorge Arturo Acevedo', NULL, NULL,
        '299ce2aba0e55ecd810854b7d061cbb9', '2026-08-01', '2027-07-31', 4000.0, 4000.0, 'EUR', 'EUR',
        'active', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "bank_transfer"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "bank_transfer"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "bank_transfer"}]'::jsonb, '', 1, now()
    ) ON CONFLICT (id) DO UPDATE SET
        tenant_name = EXCLUDED.tenant_name,
        tenant_phone = EXCLUDED.tenant_phone,
        invitee_email = EXCLUDED.invitee_email,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        monthly_rent = EXCLUDED.monthly_rent,
        tenant_notes = EXCLUDED.tenant_notes;

    INSERT INTO public.contracts (
        id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
        token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
        status, expenses_config, tenant_notes, due_day, created_at
    ) VALUES (
        'b076d82d-0722-56ba-8da6-f2dbd11ff775', '9c88e542-8da5-5fe4-a661-111e2e059b1a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'Radmila Saradzic', '+696165650', NULL,
        'ca83b90b4d955c1cafa5a1a774db5d78', '2026-08-01', '2027-07-31', 3900.0, 3900.0, 'EUR', 'EUR',
        'active', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, '--- Dnevnik Događaja ---
    [2026-08-01] Useljeni novi stanari, placena prva renta  i depozit u visini od 3.900 eur -> Sonuç: Predato Jovani
    [2026-09-01] Placena renta za septembar u iznosu od 3.900 eur
    [2026-10-01] Placena renta za oktobar u iznosu od 3.900 eur', 1, now()
    ) ON CONFLICT (id) DO UPDATE SET
        tenant_name = EXCLUDED.tenant_name,
        tenant_phone = EXCLUDED.tenant_phone,
        invitee_email = EXCLUDED.invitee_email,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        monthly_rent = EXCLUDED.monthly_rent,
        tenant_notes = EXCLUDED.tenant_notes;

    INSERT INTO public.contracts (
        id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
        token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
        status, expenses_config, tenant_notes, due_day, created_at
    ) VALUES (
        '22302dc8-29d4-5bb1-8f69-63269e5ebede', '2e42fd7e-21e3-56d5-ad1c-4a3b7b76147b', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'Kirilov Aleksei i Anastasia Saveleva', NULL, NULL,
        'c4fd19cdc1745054b2788507fc4dd107', '2026-09-15', '2027-09-14', 3350.0, 6700.0, 'EUR', 'EUR',
        'active', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, '--- Dnevnik Događaja ---
    [2026-09-15] Useljeni novi zakupci u stan, placena renta za sepembar, period od 15.09. -  30.09. u iznosu od 1.785 eur + renta za oktobar u iznosu od 3350 eur -> Sonuç: Takodje, placen depozit u visini dve zakupnine 6.700 eur
    [2026-09-23] Svo posudje, serpe, case i usisivac su prebaceni u ostavu riviere broj 081, u dve braon kutije i jedne kutije od bojlera
    [2026-09-29] Crkla masina za sudove, pozvan je ovlasceni servis Bosh i dolaze danas u 12 da poprave, takodje ostavljena i sipka za ormar koju bi danas trebali da namontiraju', 1, now()
    ) ON CONFLICT (id) DO UPDATE SET
        tenant_name = EXCLUDED.tenant_name,
        tenant_phone = EXCLUDED.tenant_phone,
        invitee_email = EXCLUDED.invitee_email,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        monthly_rent = EXCLUDED.monthly_rent,
        tenant_notes = EXCLUDED.tenant_notes;

    INSERT INTO public.contracts (
        id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
        token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
        status, expenses_config, tenant_notes, due_day, created_at
    ) VALUES (
        '5e70a56e-88ab-5268-912d-b71eb7391f8a', '500755dd-4e28-51cd-afed-2085781fd68f', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'Bojan Stanic', NULL, NULL,
        '76d9967cf3e35591b3d88c137b1ce3d6', '2026-09-01', '2027-08-31', 5000.0, 5000.0, 'EUR', 'EUR',
        'active', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, '--- Dnevnik Događaja ---
    [2026-07-30] Placen prvi deo depozita 5.000 eura -> Sonuç: Predato Jovani
    [2026-08-27] Placena renta za septembar 5.000 eur
    [2026-10-02] Placena renta za oktobar 5.000 eur', 1, now()
    ) ON CONFLICT (id) DO UPDATE SET
        tenant_name = EXCLUDED.tenant_name,
        tenant_phone = EXCLUDED.tenant_phone,
        invitee_email = EXCLUDED.invitee_email,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        monthly_rent = EXCLUDED.monthly_rent,
        tenant_notes = EXCLUDED.tenant_notes;

    INSERT INTO public.contracts (
        id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
        token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
        status, expenses_config, tenant_notes, due_day, created_at
    ) VALUES (
        '8ca471f8-d421-56a8-b807-aad6c4ab870f', '458a1035-8b78-53b8-9313-768d6c5a672a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'Philip Morris Services d.o.o. Beograd', NULL, NULL,
        '69b239f0b3e651ee9b965481e5490c16', '2026-08-01', '2029-07-31', 4850.0, 4850.0, 'EUR', 'EUR',
        'active', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "bank_transfer"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "bank_transfer"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "bank_transfer"}]'::jsonb, '--- Dnevnik Događaja ---
    [2026-08-06] Useljen stanar u 1004 i predati kljucevi', 1, now()
    ) ON CONFLICT (id) DO UPDATE SET
        tenant_name = EXCLUDED.tenant_name,
        tenant_phone = EXCLUDED.tenant_phone,
        invitee_email = EXCLUDED.invitee_email,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        monthly_rent = EXCLUDED.monthly_rent,
        tenant_notes = EXCLUDED.tenant_notes;

    INSERT INTO public.contracts (
        id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
        token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
        status, expenses_config, tenant_notes, due_day, created_at
    ) VALUES (
        '7c388da3-1229-58ad-9a2f-7769fc4c8e14', '85f588d5-a1c2-566a-b756-c4ce698dbca6', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'Milica i Luka Vildoza', NULL, NULL,
        '5bf18574b4a856ffb5893d17fe4e3e2b', '2026-08-15', '2027-08-14', 4500.0, 6750.0, 'EUR', 'EUR',
        'active', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, '--- Dnevnik Događaja ---
    [2026-08-10] Pokupljen depozit u iznosu od 5.750 eur kao i renta za period od 15.08.-31.08. u iznosu od 2.470 eur
    [2026-09-08] Placena renta u iznosu od 4.460 eur, odbijeno je 40 eur od pune cene rente jer su platili ciscenje
    [2026-10-07] Placena renta za oktobar u iznosu od 4.500 eur', 1, now()
    ) ON CONFLICT (id) DO UPDATE SET
        tenant_name = EXCLUDED.tenant_name,
        tenant_phone = EXCLUDED.tenant_phone,
        invitee_email = EXCLUDED.invitee_email,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        monthly_rent = EXCLUDED.monthly_rent,
        tenant_notes = EXCLUDED.tenant_notes;

    INSERT INTO public.contracts (
        id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
        token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
        status, expenses_config, tenant_notes, due_day, created_at
    ) VALUES (
        'c19e4b34-4b7c-5ddf-9aaa-d008e6747421', 'b34a30ae-b228-5be0-9b59-21d8980ac274', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'Artem Dzhangirian', '+79112939911', NULL,
        'c0e33ad591e95a94a45e16d0d6e50803', '2026-08-10', '2027-08-09', 4300.0, 8600.0, 'EUR', 'EUR',
        'active', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, '--- Dnevnik Događaja ---
    [2026-08-05] U utorak 04.08. preuzet depozit u iznosu od 1.000 eur, i  predat danas Jovani
    [2026-08-10] Preuzet ostatak depozita u iznosu od 7.600 eura kao i renta za period od 10.08.-31.08. u iznosu od 3.060 eur -> Sonuç: dao 10.700 eur, ostaje pretplata 40 eur
    [2026-09-08] Placena renta u iznosu od 4.260 eur, imali pretplatu 40 eur od proslog meseca
    [2026-10-02] Placena renta za oktobar 4.300 eur', 1, now()
    ) ON CONFLICT (id) DO UPDATE SET
        tenant_name = EXCLUDED.tenant_name,
        tenant_phone = EXCLUDED.tenant_phone,
        invitee_email = EXCLUDED.invitee_email,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        monthly_rent = EXCLUDED.monthly_rent,
        tenant_notes = EXCLUDED.tenant_notes;

    INSERT INTO public.contracts (
        id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
        token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
        status, expenses_config, tenant_notes, due_day, created_at
    ) VALUES (
        '46f4754a-2ed5-534f-8bb8-27b4995f5acf', '21a7b98f-23fe-5371-9895-7dfbcfd3e050', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'Kabaev Ivan', '+6211879520', NULL,
        'aa7563e5bd8e56e7b49434fe20c7699c', '2026-08-04', '2027-08-03', 4450.0, 8600.0, 'EUR', 'EUR',
        'active', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, '--- Dnevnik Događaja ---
    [2026-08-04] Potpisan ugovor sa novim zakupcem, placen depozit u iznosu od 8.600 i prva renta u iznosu od 4.450 eur -> Sonuç: Predato Jovani
    [2026-09-09] Placena renta za septembar u iznosu od 4.000 eur, odbijena mu je razlika za prvih 5 dana u avgustu i ostao je duzan 20 eur
    [2026-10-02] Placena renta za oktobar 4.450 eur, plus 20 eur dug od proslog meseca -> Sonuç: Dao 4.500 eur, ostaje pretplata 30 eur
    [2026-10-16] Uzet kljuc i dva taga iz kancelarije i data Ivanu, jedan je kljuc ostao na recepciji tako da mu i taj dajem', 1, now()
    ) ON CONFLICT (id) DO UPDATE SET
        tenant_name = EXCLUDED.tenant_name,
        tenant_phone = EXCLUDED.tenant_phone,
        invitee_email = EXCLUDED.invitee_email,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        monthly_rent = EXCLUDED.monthly_rent,
        tenant_notes = EXCLUDED.tenant_notes;

    INSERT INTO public.contracts (
        id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
        token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
        status, expenses_config, tenant_notes, due_day, created_at
    ) VALUES (
        '260f41dd-99d5-56ab-9945-be3db40881b6', 'e87ef13e-8e35-52b6-a84f-2acdf2dd72aa', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'Dominik Zane', NULL, NULL,
        'fac1d44c64a3574b93d884075122fd4f', '2026-09-10', '2027-09-09', 4500.0, 9000.0, 'EUR', 'EUR',
        'active', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, '--- Dnevnik Događaja ---
    [2026-08-07] Preuzet prvi deo depozita u iznosu od 4.500 eur -> Sonuç: Predato Jovani
    [2026-08-27] Preuzet drugi deo depozita u iznosu od 4.500 eur
    [2026-09-08] Placena renta za septembar 4.500 eur
    [2026-10-02] Placena renta za oktobar 4.500 eur', 1, now()
    ) ON CONFLICT (id) DO UPDATE SET
        tenant_name = EXCLUDED.tenant_name,
        tenant_phone = EXCLUDED.tenant_phone,
        invitee_email = EXCLUDED.invitee_email,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        monthly_rent = EXCLUDED.monthly_rent,
        tenant_notes = EXCLUDED.tenant_notes;

    INSERT INTO public.contracts (
        id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
        token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
        status, expenses_config, tenant_notes, due_day, created_at
    ) VALUES (
        '4c1baa60-2aeb-5ba0-98e9-80ea06d9ffc5', '12810dde-341d-5567-ad7b-7a4d060fe71f', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'Alexander Latinovic', NULL, NULL,
        '2f9c5d26e4355c4ea1de795138ed6176', '2026-08-14', '2027-08-13', 4350.0, 6525.0, 'EUR', 'EUR',
        'active', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, '--- Dnevnik Događaja ---
    [2026-08-14] Pokupljena renta u iznosu od 4.350 eur, Jovani dato za period od 14.08. - 31.08., ostatak ostavljen kod nas da prebacimo za sledeci mesec i da doplati koliko bude trebalo -> Sonuç: Dat i depozit u iznosu od 6.525 eur
    [2026-09-10] Placena renta za septembar -> Sonuç: Dodat iznos od 2.550 eur', 1, now()
    ) ON CONFLICT (id) DO UPDATE SET
        tenant_name = EXCLUDED.tenant_name,
        tenant_phone = EXCLUDED.tenant_phone,
        invitee_email = EXCLUDED.invitee_email,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        monthly_rent = EXCLUDED.monthly_rent,
        tenant_notes = EXCLUDED.tenant_notes;

    INSERT INTO public.contracts (
        id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
        token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
        status, expenses_config, tenant_notes, due_day, created_at
    ) VALUES (
        'af3ddb30-90bf-56e9-b8e0-4b4bf155c11b', 'd21a40f8-ebd6-5314-b063-f69e818c54d2', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'Ruza Vuksanovic', NULL, NULL,
        '0bc65607a0d65fcea6b7fd68580197a1', '2026-10-01', '2027-09-30', 4200.0, 8400.0, 'EUR', 'EUR',
        'active', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, '--- Dnevnik Događaja ---
    [2026-10-01] Useljeni novi stanari, placena renta 4.200 eur kao i depozit u iznosu od 8.400 eur', 1, now()
    ) ON CONFLICT (id) DO UPDATE SET
        tenant_name = EXCLUDED.tenant_name,
        tenant_phone = EXCLUDED.tenant_phone,
        invitee_email = EXCLUDED.invitee_email,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        monthly_rent = EXCLUDED.monthly_rent,
        tenant_notes = EXCLUDED.tenant_notes;

    INSERT INTO public.contracts (
        id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
        token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
        status, expenses_config, tenant_notes, due_day, created_at
    ) VALUES (
        '0f1747e9-30ee-5220-bcd8-1de2fe6905eb', 'd1945411-5842-52e2-9988-87b3cb9fa0fd', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'Igor Gospic', NULL, NULL,
        '7fee1deef3eb564ca66da94992235d16', '2026-10-01', '2027-09-30', 2100.0, 3150.0, 'EUR', 'EUR',
        'active', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, '--- Dnevnik Događaja ---
    [2026-09-15] Potpisan ugovor o zakupu, placen depozit u iznosu od 3.150 eur kao i prva renta u iznosu od 2.100 eur', 1, now()
    ) ON CONFLICT (id) DO UPDATE SET
        tenant_name = EXCLUDED.tenant_name,
        tenant_phone = EXCLUDED.tenant_phone,
        invitee_email = EXCLUDED.invitee_email,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        monthly_rent = EXCLUDED.monthly_rent,
        tenant_notes = EXCLUDED.tenant_notes;

    INSERT INTO public.contracts (
        id, property_id, agency_id, landlord_id, tenant_name, tenant_phone, invitee_email,
        token, start_date, end_date, monthly_rent, deposit_amount, currency, deposit_currency,
        status, expenses_config, tenant_notes, due_day, created_at
    ) VALUES (
        '2dcd3938-83f0-561c-a7aa-2fa55d9ea465', '2958095f-a25c-58aa-ab38-476cb0f954eb', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'Nikola Jovanovic', NULL, NULL,
        'b267792895595174a0905ee77a3e08f6', '2026-09-16', '2027-04-30', 2300.0, 4600.0, 'EUR', 'EUR',
        'active', '[{"name": "Infostan", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Electricity", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}, {"name": "Building Maintenance", "receiver": "owner", "amount": 0.0, "payment_method": "cash"}]'::jsonb, '--- Dnevnik Događaja ---
    [2026-09-16] Placena prva renta u iznosu od 1150 eur za period 16.09.-30.09 i depozit u iznosu od 4.600 eur
    [2026-10-01] Placena renta za oktobar u iznosu od 2.300 eur', 1, now()
    ) ON CONFLICT (id) DO UPDATE SET
        tenant_name = EXCLUDED.tenant_name,
        tenant_phone = EXCLUDED.tenant_phone,
        invitee_email = EXCLUDED.invitee_email,
        start_date = EXCLUDED.start_date,
        end_date = EXCLUDED.end_date,
        monthly_rent = EXCLUDED.monthly_rent,
        tenant_notes = EXCLUDED.tenant_notes;


    -- ------------------------------------------------------------------------------
    -- 2.5 ACTIVITY LOGS (Dnevnik Događaja -> manual_note)
    -- ------------------------------------------------------------------------------
    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'f0b2f6c6-1e58-573c-8cc7-7e0e4cf8b1b2', '054fc448-a11b-54fc-9f66-f6e913fe84d4', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Zakupac platio 2.850 EUR, 2.300 EUR renta za jul i računi bez struje su bili 470 EUR. Imao pretplatu od 9.160 RSD (Sonuç: ZAKUPAC NIJE PLATIO STRUJU ZA MAJ, JUN, JUL I AVGUST)'), now()
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'c6577cee-8caa-5bf4-abd3-f17c3bd3b8a5', '054fc448-a11b-54fc-9f66-f6e913fe84d4', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Od pretplate u iznosu oD 9.160 RSD odbijeno 4074 RSD za internet, ostalo 5136 RSD'), '2025-08-04 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '26d393e1-c27b-5bc4-87b3-b95a3bfc9b5c', '054fc448-a11b-54fc-9f66-f6e913fe84d4', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placen je internet za 104 Terraces za jul 2025 u iznosu 2040 rad + 60 rsd provizija, ukupno 2100 rsd, iskoriscena pretplata koju ima (5136 rsd), tako da pretplata sada iznosi 3036 rsd.'), '2025-08-08 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '8e83bc58-a7e5-50b3-bed1-1cd9fcd4e54b', '054fc448-a11b-54fc-9f66-f6e913fe84d4', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Zakupac obavešten da treba da plati 2.300 EUR rentu za avgust, 51.580,82din računi za jun i 55.247,54 računi za jul (obavešten je da za oba meseca nisu stigli računi za struju) (Sonuç: Primljeno od zakupca 2.740 EUR, 2.300 renta za avgust i 440 EUR računi za jun)'), '2025-08-13 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'd56950e8-3c47-5f63-abc4-409245fa4789', '054fc448-a11b-54fc-9f66-f6e913fe84d4', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Zakupac obavešten za rentu za septembar 2300 EUR i računi za jul 55.414,52 (475 EUR) bez struje'), '2025-08-29 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'c4e7a5a1-0956-5d29-b35e-4d00a7599fc5', '054fc448-a11b-54fc-9f66-f6e913fe84d4', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Jovana poslala račun za EPS za avgust - 15.396,78 din'), '2025-09-17 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '9ede8cc2-fe14-54e2-bd59-651894c90e5d', '054fc448-a11b-54fc-9f66-f6e913fe84d4', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'EPS poslao korigovane račune. Jun - umesto 65.340,74 din iznos od 9.619,57 din. Jul - umesto 75.638,18 din iznos od 11.257,33 din'), '2025-10-02 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '4a21faa6-570a-55f3-a779-db913fd3d029', '054fc448-a11b-54fc-9f66-f6e913fe84d4', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Ukupno za EPS jun, jul i avgust je 310 EUR, a pretplata koju zakupac ima je 225 EUR (Sonuç: Treba da doplati 85 EUR za EPS)'), '2025-10-10 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'c5d7d554-44be-5ac2-b103-a22261fe5252', '054fc448-a11b-54fc-9f66-f6e913fe84d4', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Zakupac dao novac za rentu i 200 EUR za račune (Sonuç: Duguje još 370 EUR regularno + još 85 za EPS)'), '2025-10-20 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '3734cb61-b6fb-59bf-86e0-7e8dab908d73', '054fc448-a11b-54fc-9f66-f6e913fe84d4', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'depozit zakupca - 4600e: 2300e renta za novembar, 550e racuni septembar, 510e racuni oktobar (ukljucujuci internet),550e racuni novembar (bez interneta),350e dug od avgustovskih racuna,120e ciscenje stana, 85e doplata za struju,ukupni troskovi 4465e, ostaje od depozita 135e'), '2025-11-01 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '836e14a6-0ef5-58a8-917b-cdf27d72e607', '054fc448-a11b-54fc-9f66-f6e913fe84d4', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Novi zakupci - Narcis Bečirović i Ana, useljavaju se 20.11.2025. Potpisan Ugovor o zakupu, i zapisnik o primopredaji. (Sonuç: Prilikom potpisivanja, platili: prvu mesečnu zakupninu u iznosu od 2.500 EUR, kao i depozit u visini od 3.700 EUR.)'), '2025-11-19 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '1e5bea27-51ba-5f78-aa31-9c09ef141348', '054fc448-a11b-54fc-9f66-f6e913fe84d4', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Zameniće se kreveti u stanu 104 i 207 u BW Terraces tako da će single krevet iz 207 da se prebaci u ostavu a bračni iz 104 u 207.'), '2025-11-20 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '99746353-18b8-5cdc-bea8-99d7185ef4e1', '054fc448-a11b-54fc-9f66-f6e913fe84d4', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Stanarka prijavila da joj ne radi mašina za pranje sudova.'), '2025-11-24 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '6e6d4a83-ab08-5f79-958d-c1ef36748824', '054fc448-a11b-54fc-9f66-f6e913fe84d4', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Angažovan majstor iz Bosch-a da popravi mašinu za sudove, mašina je popravljena. (Sonuç: Popravka mašine plaćena 6.000 dinara)'), '2025-11-25 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '49b8f451-9c4d-5613-97a1-31fc17e1ea0a', '054fc448-a11b-54fc-9f66-f6e913fe84d4', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Izneto iz stana: TV iz dnevne sobe, mikrotalasna i dve zlate stone lampe i preneto u stan 207'), '2025-12-03 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'ad53330f-de6a-5848-8624-f9808f133a0f', '054fc448-a11b-54fc-9f66-f6e913fe84d4', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Zakupac trazio dubinsko pranje duseka u master sobi (Sonuç: Poslato je dubinsko, platila je sama 3000 rsd, odbiti im od kirije)'), '2025-11-27 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'bbac0f43-802c-541f-b9f1-0175e7932a8a', '054fc448-a11b-54fc-9f66-f6e913fe84d4', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Tražila je da se kupi naddušek za master sobu (Sonuç: Kupila je sama u Yisku i tražila je da joj se odbije od kirije 21.700 rsd)'), '2025-11-30 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '19f49dd9-f5b8-5b29-8662-d1ff459e46cb', '054fc448-a11b-54fc-9f66-f6e913fe84d4', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Platila 2290 eura za period 20.12. do 19.01. Odbijeno joj je 210 eura za naddušek i dubinsko čišćenje dušeka. Za 11 dana novembra dala 200 eura za račune'), '2025-12-19 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '08b1b411-bb5e-5486-a0d1-e2238711509c', '054fc448-a11b-54fc-9f66-f6e913fe84d4', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Platila 2.500 EUR rentu za period od 20.01. - 19.02.2026. + 650 eur za racune za decembar'), '2026-01-20 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'edd63820-cc73-555a-8e7e-5582df772e8d', '054fc448-a11b-54fc-9f66-f6e913fe84d4', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Platila 2.500 EUR rentu za period od 20.02. - 19.03.2026. + 705 eur za racune za januar'), '2026-02-20 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '2a1cc083-042d-519b-aa3d-e11856dc1a03', '054fc448-a11b-54fc-9f66-f6e913fe84d4', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Platila 2.500 EUR rentu za period od 20.03. - 19.04.2026. + 655 EUR za racune za februar'), '2026-03-20 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '4824c3ed-f09f-5ac4-99de-903d0127ad1c', '054fc448-a11b-54fc-9f66-f6e913fe84d4', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Platila 2.500 EUR rentu za period od 20.4. - 19.05.2026. + 600 EUR + 1000 din za racune za mart'), '2026-04-21 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '4f1e2e28-670f-50bf-b07b-ee4d188edb1f', '054fc448-a11b-54fc-9f66-f6e913fe84d4', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Nataša je donela Ani usisivac iz stana C 7.28 jer se usisivac iz stana 104 pokvario, pokvaren usisivac je kod Natase u gepeku'), '2026-04-21 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '0723de3d-a6ed-5f23-ae8f-0ed378f7dfc7', '054fc448-a11b-54fc-9f66-f6e913fe84d4', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Platila 2.500 eur rentu za period od 20.05. - 19.06.2026. + 69.000 dinara za racune za april'), '2026-05-20 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '278b84bd-42d1-5ae7-851e-438c578f7b0a', '054fc448-a11b-54fc-9f66-f6e913fe84d4', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Platila 2.500 eur rentu za period od 20.06. - 19.07.2026. + 600 eur za racune za maj (Sonuç: Pretplata 35 eur za naredni mesec)'), '2026-06-20 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '42688ba0-01d8-51fe-b942-83877bfde0c5', '054fc448-a11b-54fc-9f66-f6e913fe84d4', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Platila 2.500 eur rentu za period od 20.07. - 19.08.2026. + 500 eur i 600 din za racune za jun (Sonuç: Dala je manje 35 eur koliko je ostala pretplata)'), '2026-07-20 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'de805c2d-6660-5c86-b8a9-ed01070081a4', '054fc448-a11b-54fc-9f66-f6e913fe84d4', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Krevet iz spavace sobe iz 104 Terraces prebacen u 2104 u Rivieru'), '2026-08-06 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '55e30f5a-b758-5f99-8b23-e331e8e4cca3', '054fc448-a11b-54fc-9f66-f6e913fe84d4', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Platila 2.500 eur rentu za period od 20.08.-19.09.2026. + 350 eur za racune (Sonuç: Ukupni racuni su 64.222,34 dinara, odbijeno 24.000 za komarnike)'), '2026-08-20 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'f5a637be-a7cc-5a8d-8f46-2950aedf1614', '054fc448-a11b-54fc-9f66-f6e913fe84d4', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Platila 2.500 eur rentu za period od 20.09.-19.10.2026. + 550 eur i 1.300 din za racune'), '2026-09-17 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'e902c7c1-c1d3-5bad-806e-0f82c8ea95e6', '054fc448-a11b-54fc-9f66-f6e913fe84d4', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Sto i stolica  iz master spavace sobe prebacen u stan 2203 u Rivieru, dok je nocni stocic prebacen u 2401 Perla, a drugi nocni stocic je u stanu 207'), '2026-09-23 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '517d8a53-b013-5159-bc10-99bfe972c0ac', '4a1858ac-cd89-5ded-a31b-67561b05923f', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Računi za avgust 51.747,47 i da nedostaje račun za struju (obavešten u poruci)'), '2025-10-08 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'c0f3b9b8-33ea-59a3-aee5-f67d614a398b', '4a1858ac-cd89-5ded-a31b-67561b05923f', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Tepisi iz dnevne sobe bili na dubinskom pranju (Sonuç: Vraćeni u stan 04.11.)'), '2025-11-04 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '4e9da5a2-bef4-5452-b1cb-5ada3a7d61aa', '4a1858ac-cd89-5ded-a31b-67561b05923f', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Gledanje stana sa Vojinom iz agencije Brick pro u 10h'), '2025-11-05 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '563023b3-8806-5154-a6db-77311504d6f7', '4a1858ac-cd89-5ded-a31b-67561b05923f', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Od depozita zakupca Jovana Avram, odbijeno je: 64.026,97 rsd za račune za septembar i 63.715,06 rsd za račune za oktobar, a ostatak u iznosu 1658 EUR iskorišćeno za deo rente za novembar'), '2025-11-06 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'a738894a-160d-5364-9bd5-2437e88ad7db', '4a1858ac-cd89-5ded-a31b-67561b05923f', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'NOVI ZAKUPAC - uselio se u stan Kostiantyn Kuzmenko (Sonuç: Data prva renta u iznosu od 2.500 EUR i dva depozita 2.500 EUR x 2 = 5.000 EUR)'), '2025-12-02 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'b4360a30-36ad-5c94-b47e-4431a2dc7960', '4a1858ac-cd89-5ded-a31b-67561b05923f', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Potrebno je premestiti bracni krevet iz prve spavace (koji je tu stavljen iz prve spavace stana 104) u master sobu a sivi kozni krevet izbaciti iz stana i odneti u magacin u Sremcicu. Televizor, mikrotalasna i dve zlatne lampe iz stana 104 preneto u stan 207. Potrebno je kupiti nogice za tv koji je donet iz 104 i montirati tv u master spavacu na komodu (Sonuç: Sivi krevet iz master sobe je ipak ostao u stanu a atlas krevet koji je iz stana 104 donet u gostinsku sobu prenet je u magacin u Banovce kod Nikole Korde. Takodje je iznet i radni sto i stolica u isti magacin. Nocni stocic i dve zlatne lampe iz stana 104 ostali su u gostinjskoj sobi stana 207)'), '2025-12-03 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '6469925a-6207-5eca-82ca-159841943d79', '4a1858ac-cd89-5ded-a31b-67561b05923f', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Preuzeta kirija za mart u iznosu od 2500 EUR i novac za racune za januar u iznosu od 530e (Sonuç: Zakupac je dao 3000 EUR i 5000 din, u pretplati je 1490 din)'), '2026-03-10 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '3934c21a-8028-5d8a-beb2-71074df19896', '4a1858ac-cd89-5ded-a31b-67561b05923f', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Struja nije ocitana za februar, stavljen iznos kao i za prosli mesec'), '2026-03-26 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '5344e4f4-de8a-5384-a398-dc0c31d7f961', '4a1858ac-cd89-5ded-a31b-67561b05923f', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Poslata poruka za placanje rente za april i racuna za februar'), '2026-04-01 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'bf67c492-02ac-574e-8e9d-7fddbfe8aadc', '4a1858ac-cd89-5ded-a31b-67561b05923f', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za april i racuni za februar (Sonuç: 3100e dao, ima pretplatu iz prethodnog perioda)'), '2026-04-06 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'b8331784-3495-5640-bbbc-316e51c68d2f', '4a1858ac-cd89-5ded-a31b-67561b05923f', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Struja je stigla 33.337,37, obzirom da za februar struja nije ocitana, mi smo naplatili 8.805.30 kao za januar, tako da cemo od ovog iznosa oduzeti tih 8 hiljada i dodati osnovicu od 2.290,73 dinara (Sonuç: Naplata za mart ce biti 26.822,80)'), '2026-04-29 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '47a922b7-14cb-5e25-aeb8-5a67c6f139c6', '4a1858ac-cd89-5ded-a31b-67561b05923f', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za maj i racuni za februar (Sonuç: 380.000 dinara dao, 1993,26 dinara pretplata)'), '2026-05-06 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'd91a40e1-23dd-5ffb-8c7a-e6d7ce2f2d6e', '4a1858ac-cd89-5ded-a31b-67561b05923f', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Zakupac kontaktiran u vezi placanja rente za jun i racuna za april, ali nije u zemlji pa je rekao 9-10 juna da ce biti tu'), '2026-06-02 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '802488ea-5868-51e1-b383-18df1aa74c6d', '4a1858ac-cd89-5ded-a31b-67561b05923f', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Preuzeta kirija za jun u iznosu od 2500 EUR i novac za racune za april u iznosu od 550e (Sonuç: Pretplata 2.880 dinara)'), '2026-06-09 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'fa69df5a-ed38-5802-abe6-0387fb5aa74e', '4a1858ac-cd89-5ded-a31b-67561b05923f', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Pruzeta kirija za jul + novac za racune za maj (Sonuç: 355.000 dinara + 1500 din uzeto iz pretplate)'), '2026-07-09 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '20c60d83-c82b-50dd-a32f-4920750277d5', '4a1858ac-cd89-5ded-a31b-67561b05923f', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Preuzeta kirija za avgust + novac za racune za jun (Sonuç: 2.500 eur renta + 500 eur i dve hilj za racune)'), '2026-08-05 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '32939256-3bb9-56c0-bebb-173e52b5d7ed', '4a1858ac-cd89-5ded-a31b-67561b05923f', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Preuzeta kirija za septembar + novac za racune za jul (Sonuç: 2.500 eur renta + 600 eur za racune, ostaje pretplata 43 eur)'), '2026-09-08 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '76a7228a-8343-5182-b7cd-e12dabc8b091', '4a1858ac-cd89-5ded-a31b-67561b05923f', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Preuzeta kirija za oktobar + novac za racune za avgust (Sonuç: 2.500 eur renta + 520 eur racuni za avgust + pretplata)'), '2026-10-13 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'adb38c7f-d5a2-5d4e-a451-4829ce687dcf', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Miroslav je tražio daljinski i tražio je da se stakleni sto iznese iz njegovog stana (Sonuç: Daljinski uzet iz stana 0901 West i biće mu odnešen)'), '2025-11-04 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'f4f76432-7477-5241-b75d-d7bbf1dba271', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Miroslav platio rentu za januar i račune za novembar'), now()
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '717409ae-5683-517d-8b69-f867ed8f6aa5', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Novi problem u stanu 1501, BW Simfonija. U pitanju je curenje vode, ovoga puta iz kupatila (ne sa terase).
    Komšinica iz stana 1401 me je obavestila da joj voda curi iz plafona u spavaćoj sobi i kaplje direktno na krevet.
    Odmah smo kontaktirali izvodjaca radova - Milenium tim. Obavešteni smo da zgrada više nije u garanciji, ali da će nam izaći u susret i izvršiti pregled. Nakon ulaska u stan i provere, utvrđeno je da voda zaista prodire iz našeg kupatila u stan ispod.
    Danas sam dobila poziv od Milenium tima sa pitanjem kada mogu da započnu radove u kupatilu. (Sonuç: Zakupac je bio izrazito nezadovoljan zbog ponovnog uznemiravanja, a nakon informacije da će biti neophodna sanacija kupatila, izjavio je da namerava da napusti stan.)'), '2026-02-11 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'dbbfa3cc-b26d-56d1-9c01-16df537b9aae', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Smanjena renta sa 3600e na 3200e (Sonuç: Zbog nekoriscenja drugog kupatila zakupcu je smanjena renta)'), '2026-02-23 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'b2ae32b8-2e5e-5a54-b48f-0d2f28d59811', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Poslata mu je poruka u vezi placanja rente za mart, dana 09.03.'), now()
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '491322fe-4992-5327-8fd3-269cc978682c', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Uraditi Aneks ugovora sa smanjenom rentom'), now()
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '36f9540c-c6a4-549c-a8b9-2e31bef3a999', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Preuzeta kirija od zakupca 3200 EUR'), '2026-03-10 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '7532ef7d-4d1e-5dc1-838d-98324ce11808', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Poslata poruka u vezi placanja rente i racuna za februar, takodje smo ga pitali da li zeli da produzi ugovor, obzirom da mu istice u aprilu (Sonuç: Rekao je da zeli da produzi na 6 meseci, u cetvrtak 09.04. je dogovor da potpise)'), '2026-04-01 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '056f6244-0517-5996-9ab0-78627d1c56f2', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Miroslav je dao 3.150 evra, i nije dao novac za racune, rekao je da ce dati u toku sledece nedelje, jer nije imao novac u kesu, tada ce dodati i 50e za kiriju'), '2026-04-09 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'bddadebd-320d-51d8-9f42-04087eb67f7c', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Miroslav dao 4010 EUR za rentu za maj, i racune za februar (Sonuç: 3200e renta za maj + 50e dug od rente za april + 760e racuni za februar)'), '2026-04-25 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '4dd3237f-1a3a-591a-b9f7-3d40ec508c3c', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Stavljena struja iznos kao za februar, posto nije za mart stigla'), '2026-05-04 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '0e71c09d-dd3e-5aba-a00a-2a8a8b52854d', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Pokupljen novac za racune za mart 650 EUR (Sonuç: Duguje 18 eur ukupno ( 7 eur za mart, za novembar 6e i za oktobar 5 e))'), '2026-05-19 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'fdaddc1b-57d2-538c-90d8-aae3a8adc9f6', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Zakupac je kontaktiran u vezi placanje rente i racuna, nije u zemlji i bice tek oko 20-og'), '2026-06-05 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '305f167c-bbfe-5ea9-adaf-a28b5b9e56d8', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za jun i jul u iznosu od 6.400 eur + za racune za april i maj  dao 1260 eur (Sonuç: Struja jos uvek nije stigla tako da sam mu uzela iznos kao i za prosli mesec)'), '2026-06-26 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'b762383c-a2b7-5637-9d6a-68afecddadd6', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za avgust 3.200 eur + za racuni za jun 620 eur (Sonuç: Struja stigla, tako da je doplatio i tu razliku od 2.000 din)'), '2026-07-28 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '6626d3e0-9f09-5490-805e-a4fa0ab9b5c3', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za septembar 3.200 eur + za racuni za jul 670 eur'), '2026-09-16 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '6ad9b02a-7184-501c-850e-e7200df25fca', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za oktobar 3.200 eur + za racuni za avgust 600 eur'), '2026-10-16 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '3f241374-315c-5037-95c1-dcf45ebb82ef', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Prijavljen problem na terasi stana - došlo je do odvajanja dela plafona terase – ukrasne obloge / fasadnog elementa (gipsane ili slične završne obrade), koji trenutno visi i postoji realna opasnost da padne.
    Prema onome što je vidljivo sa terase, deluje da dolazi do podlivanja vode sa terase stana iznad, usled čega se materijal na plafonu naše terase natapa i odlepljuje.'), '2026-02-18 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '5373cfe3-92d1-511f-bba1-7222e2832859', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Uraditi aneks ugovora'), now()
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'e4fc73ee-7bab-5e69-85a4-2365bd720598', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Stigao je račun za struju u iznosu od 88.371,78 za ceo prethodni period za koji su zakupci u stanu'), '2026-03-18 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '87324ae0-7707-57b5-ad00-07198e108f5f', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Jovana mailom potvrdila da je placena renta za mart 27.03.2026.'), '2026-04-02 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '1e17ddc1-7240-5af6-91eb-0ba160357825', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Jovana mailom potvrdila da je placena renta za april 16.04.2026.'), '2026-04-17 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '4d3d61ad-1844-55f0-85a5-e8bf703c5257', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Jovana mailom potvrdila da su placeni racuni za januar i februar'), '2026-04-21 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'af2b9410-0306-552b-b32a-0bde1065f377', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Jovana mailom potvrdila da su placeni racuni za decembar 2025. (Sonuç: Uplacen iznos od 60.858,37)'), '2026-04-30 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '7c7b38f8-80e2-5285-9e2e-2a4351a48f52', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Jovana mailom potrvdila da je placena renta za maj 2026 (Sonuç: 3.000 eur)'), '2026-05-14 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '7ef90b98-c4ce-5095-955d-44536bedbc46', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Jovana mailom potvrdila da je placena renta za jun 2026'), '2026-07-30 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '909d6676-26fd-55c5-9897-8b34aca7eb2a', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Jovana mailom potvrdila da je placena renta za avgust 2026'), '2026-08-24 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '13512a58-656c-501e-86f5-333a46359a58', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Jovana mailom potvrdila da su placeni racuni za mart, april i maj'), '2026-09-03 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '035f92b2-55f4-528a-8c7a-2a698d91545d', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Obavesten 01.03., rekao da je na putu. Obavesten opet o iznosu za placanje, kirija mart i racuni za januar dana 09.03.'), now()
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'f73e49b7-a294-5792-8fd0-a468484261e7', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Pokupljena kirija za mart 1800e plus 350e za racune (Sonuç: pretplata 3000 dinara za racune)'), '2026-03-19 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '138cdc99-2727-5b34-8dea-c6e12403e6d4', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Obavesten o placanju rente za april i racuna za februar, rekao da se nadjemo u ponedeljak'), '2026-04-01 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '63f4e353-697c-505b-902d-a923369b9c31', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Dao rentu za april 1800e plus racune za februar 39.000 (Sonuç: u pretplati  3000 od prosli put)'), '2026-04-06 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '3f5c0cce-7a4c-54be-9f6d-2aeb9a6a434d', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Racun za struju nije stigao za mart, tako da je stavljena ista cifra kao i za februar'), '2026-04-29 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '13755b6a-5682-5229-91b1-990815c21649', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za maj i racuni za mart (Sonuç: 1800 eur + 37.000 dinara za racune)'), '2026-05-08 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'c60dd32d-fc46-51ca-80c0-710a204088aa', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Usao je novi zakupac Borko - Obzirom na to da je Nikola platio rentu za ceo mesec, vraticemo mu razliku kada budu dospeli i racuni (Sonuç: Placen je depozit 2.700 eur + prva renta 1800 eur)'), '2025-05-15 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '8184db21-f370-512f-a637-df3511b9c2b3', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Nikoli vracen depozit u visini jedne mesecne rente i razlika za maj obzirom da je ranije izasao iz stana a platio je ceo mesec (Sonuç: 1.800 eur za depozit + 1045 eur za razliku)'), '2025-05-28 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'aa2640b3-7de3-5629-8f2b-f6509b64cf70', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Od Borka pokupljena renta u iznosu od 1050 eur za jun (Sonuç: uzeto 300 eur za aprilske racune od 900 eur koji su ostali od Nikole da pokriju troskove)'), '2026-06-03 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '0c8a9608-cbb4-51b7-9d66-2eb331831abf', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Pokupljena kirija za jul 1800e + 13.400 dinara za racune za period od 13.05.-31.05'), '2026-07-01 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '6cf38711-a78d-5342-8811-1629e8ccd19d', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Pokupljena kirija za avgust 1.800 eur + novac za racune za jun + deo info stana za maj za period od 14.05.-31.05. (Sonuç: Ukupno 40.000 dinara)'), '2026-07-31 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '1ebcb0a9-87ec-5759-a714-7185bdecd825', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Jovani dato 100 eur + 2000 din iz gladoviceve koverte za racune za maj od 01.05.-13.05.'), '2026-08-03 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '51bbd87a-1a19-564d-ba77-20fd27f542fb', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za septembar 1800 eur + 32.200 din za racune za jul'), '2026-09-01 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'b1a61ed6-1669-5261-aa4a-bfab1c0db663', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Bojler u stanu crkao, pozvan servis, odnosno morace novi bojler, jos uvek se ne zna cena'), '2026-09-29 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '58192c82-bc6f-58d3-94d4-3c038d94fbb3', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za oktobar (1.800 eur) kao i racuni za avgust 32.100 dinara'), '2026-10-01 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '7cc83a78-dc36-5185-baf8-8d554f758362', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Popravljen bojler u stanu, popravka je iznosila 16.900 dinara'), now()
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '1c8475ea-3903-51b8-8f94-f1c9f21f7afc', '3202a566-41ba-594d-8870-f5f37147e9a0', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', '2900e - renta za oktobar 2600e + racuni za avgust 300e (racuni su 38.661,26 + provizija 441.03 = ukupno 39.102,29 / 334e - pretplata 45e = 289e (Sonuç: zakupac sada ima novu pretplatu 11e)'), '2025-10-03 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '10be8eed-52dd-5a8c-9f2d-88fe2b6df150', '3202a566-41ba-594d-8870-f5f37147e9a0', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Popravljena balkonska vrata iz dnevne sobe i popravljena balkonska vrata iz master spavaće sobe (Sonuç: Plaćeno sve 100 EUR)'), '2025-11-24 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '2fd1e029-c5bf-55e7-aed2-66d0affa546a', '3202a566-41ba-594d-8870-f5f37147e9a0', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Bila Boba da skine zavese, pa su iz perionice veša došli i pokupili zavese. Takođe, Nataša odnela sedalni deo ugaone garniture u Zemun na ušivanje, jer se rašila. (Sonuç: Uslugu skidanja i nameštanja zavesa Bobi plaćamo 4.000 dinara, a pranje zavesa 34.970 dinara.)'), '2025-11-25 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '5de82e0e-56d4-59c1-8aaf-ea9c347a744d', '3202a566-41ba-594d-8870-f5f37147e9a0', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Depozit od Gizem u iznosu od 3.900 EUR: - 2.600 EUR zakupnina za novembar, 350 EUR troškovi za septembar, 350 EUR troškovi za oktobar, 380 EUR troškovi za novembar (Sonuç: Nakon svih ovih odbitaka, preostali iznos je 220 EUR koji je refundiran)'), '2025-11-26 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '2bf2be38-a395-5c5c-9d82-33149952981e', '3202a566-41ba-594d-8870-f5f37147e9a0', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Pranje sofe plaćeno 4.000 dinara, ušivanje sedišta sofe plaćeno 3.000 dinara i dato čistačicama (2 čistačice po 8h) 16.000 dinara'), '2025-12-01 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'f883aa81-17ab-5ef3-b770-994843c01673', '3202a566-41ba-594d-8870-f5f37147e9a0', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'I mesečna kirija - 01.12 - 31.12. 2025. (Sonuç: 2.450 EUR (1.900 EUR + 64.350 RSD))'), '2025-12-02 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'd59c4d7e-2046-5a5f-a451-f26f819cad6d', '3202a566-41ba-594d-8870-f5f37147e9a0', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Računi za novembar plaćeni iz depozita od Gizem (Sonuç: Naplatićemo i Nikolaju 10 dana računa za novembar)'), '2025-12-15 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '9f38d2f3-e6ae-5994-bcfc-0aa96dae2ebb', '3202a566-41ba-594d-8870-f5f37147e9a0', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Nikolaj platio račune za decembar - 55.200 dinara (Sonuç: PREBACITI U NOVU TABELU)'), '2026-01-21 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '438bf246-f3d4-53c0-a32f-3295f739b856', '3202a566-41ba-594d-8870-f5f37147e9a0', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Nikolaj dao kiriju za februar 2.450 eura (Sonuç: PREBACITI U NOVU TABELU)'), '2026-02-04 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'ca15f049-0271-50ec-8048-765814cd583c', '3202a566-41ba-594d-8870-f5f37147e9a0', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena kirija 2.450 eura za mart i racuni za januar (Sonuç: 2.450 eur + 59.480 rsd)'), '2026-03-03 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '2d034918-9d24-54aa-90c1-8acc5293ed02', '3202a566-41ba-594d-8870-f5f37147e9a0', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena kirija 2.450 eura za april i racuni za februar (Sonuç: 2.450 eur + 62.500 rsd)'), '2026-04-02 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '97f24ad1-85a2-5e9f-96ab-457bcd30e1b8', '3202a566-41ba-594d-8870-f5f37147e9a0', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena kirija 2.450 eur za maj i racuni za mart (Sonuç: 2.450 eur + 57.660 rsd)'), '2026-04-28 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'ae37643c-547c-56e2-9dd8-ac84c47cae5f', '3202a566-41ba-594d-8870-f5f37147e9a0', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena kirija 2.450 eur za jun i racuni za april (Sonuç: 2.450 eur + 52.860 rsd)'), '2026-06-03 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '0b003e03-88c4-594e-847b-53846783d3b7', '3202a566-41ba-594d-8870-f5f37147e9a0', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena kirija 2.450 eur za jul i racuni za maj (Sonuç: 2.450 eur + 54.350 rsd)'), '2026-07-01 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'af6c90e3-9cbc-5f07-8b46-653efa84f04f', '3202a566-41ba-594d-8870-f5f37147e9a0', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena kirija 2.450 eur za avgust i racuni za jun (Sonuç: 2450 eur + 51.640 rsd)'), '2026-08-05 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'd5f0d017-8335-5c34-ade8-08a4ebddd4e5', '3202a566-41ba-594d-8870-f5f37147e9a0', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena kirija 2.450 eur za septembar i racuni za jul (Sonuç: 2450 eur + 52.100 rsd)'), '2026-09-08 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '0e16e64d-5fbf-5d78-bfcf-2730a6839a2d', '3202a566-41ba-594d-8870-f5f37147e9a0', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena kirija 2.450 eur za oktobar i racuni za avgust (Sonuç: 2450 eur + 58.810 rsd)'), '2026-10-01 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'a1116c56-6266-5bdc-ade0-4e81a9a640a1', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Zakupac se zalio na prljave prozore iako su bili alpinisti da ih ociste i trazio da se resi problem. (Sonuç: Pronašla sam profesionalne čistače prozora koji poseduju adekvatnu opremu za čišćenje unutrašnjih površina. Radi se o ruskoj agenciji specijalizovanoj za usluge čišćenja.)'), '2025-04-30 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '3c726461-87c1-593c-9e8e-9e01c34bbbe9', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Zakupac je imao problema sa klimom. (Sonuç: Organizovali smo ovlasceni servis klima uredjaja.)'), '0205-06-04 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '632de67e-9e8c-5a62-9e4a-5f30e5d8bea8', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Pokupljena kirija od zakupca Ivana, nije više 2600 eur nego 2500 eur'), '2025-10-06 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'b1a68386-2693-5f68-b3da-21721a485867', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Pokupljena kirija od zakupca'), '2025-12-05 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '9cf861d6-478b-5fd7-ac86-fe5fe41651e0', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Zakupac se više puta obratio zbog nečistoće u zgradi, prljavih spoljnih prozora i kvara ulaznih vrata zgrade (Sonuç: Pozvan upravnik zgrade više puta i poslato više mejlova sa zahtevom zakupca)'), '2025-01-08 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '74b704b6-365a-5b7a-b64b-df7f4e5de533', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Pokupljena kirija od zakupca 2500e'), '2026-03-04 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '8585488b-c5a9-5a17-a6d6-1301acf188a2', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Obavesten za placanje rente za april'), '2026-04-02 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'cba6435a-4844-52c5-88e5-e8015ea10a28', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za april 2.500e'), '2026-04-06 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '4d516af0-8fc0-5319-94dc-59b297de88f5', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za maj 2.500e'), '2026-05-04 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '384ff77c-618d-5ff3-921b-4c2a0e38a9bb', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Ivan nas je kontaktirao da opet ne radi klima, obzirom da se javlja isti problem posle manje od godinu dana, kontaktirale smo upravnika, ali smo dobile odgovor da ne moze nista da uradi. Obzirom da je bio petak, nismo mogli da pronadjemo majstora, a on je hteo odmah da se resi pa je sam organizovao majstore. Popravka je iznosila 530 eur, s tim sto je Ivan rekao da ce dati 200 eur. Sve slike i izvestaj se nalaze u folderu popravki.'), '2026-05-12 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'e4a33591-88e9-5492-a6df-7c68cdc7edec', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Sa zakupcem postignut dogovor da ce se troskovi za popravku klime koja je iznosila 530 eur podeliti na pola, tako da je polovina odbijena od rente (Sonuç: Zakupac je platio rentu u iznosu od 2.232,5 eur)'), '2026-06-03 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '34cf410d-b077-58e0-8e70-2b14752b9d6f', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za jul  2.500 eur'), '2026-07-02 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'cea10ba4-b691-518c-977b-a3a0b471770e', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za avgust 2.500 eur'), '2026-08-06 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'd2843155-c2e3-5d6f-b5fe-a84984d2c441', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za septembar 2.500 eur'), '2026-09-01 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '6f8fcb71-edd5-547c-9db2-714fd23383b9', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za oktobar 2.500 eur'), '2026-10-02 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'fa243ed9-a73a-54da-ab66-51d740d43f04', '795db987-07d2-515b-84cd-1656f271953d', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Za 9.1 West kulu nam je ostao jedan ceo depozit od bivseg stanara I od tog iznosa treba da odbijemo 60 eur za ciscenje i odbicemo mu sve dane u oktobru dok je stan prazan, taj presek cemo uraditi na kraju meseca jer ne znam od kog datuma cemo izdati stan (nemamo jos uvek nove stanare) (Sonuç: 01.10.2025 Zakupcu je od depozita u iznosu od 1800 eur odbijeno 840 eur za racune za jul, avgust i septembar, vraceno mu je 960 eur. Jos jedan depozit u iznosu od 1800 eur ostao je kod nas)'), '2025-10-02 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'b57c3a87-7fa6-5015-8a04-8b57e4bfdb54', '795db987-07d2-515b-84cd-1656f271953d', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', '9.1 Julski racuni u iznosu od 36.186 rsd naplaceno od depozita'), now()
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '2ecb2c2b-c999-5f22-a7bf-0001b8c5c7db', '795db987-07d2-515b-84cd-1656f271953d', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', '9.1 Nisu stigli svi racuni za avgust (Form focus) zakupcu izracunato prosecno 36.000 i naplacano od depozita'), now()
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '1aba6a92-0632-57c3-a36f-9866df004f2d', '795db987-07d2-515b-84cd-1656f271953d', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', '9.1 Nisu stigli svi racuni za septembar (Form focus) zakupcu izracunato prosecno 36.000 i naplacano od depozita'), now()
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '01872393-4c1d-5b64-b167-9b3380d06975', '795db987-07d2-515b-84cd-1656f271953d', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Imao pretplatu 84 eur, (bila je 105 eur, ali je odbijeno za karticu 21 eur)'), now()
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'dc4892a0-cd5a-5b8c-84d1-e9730650a43c', '795db987-07d2-515b-84cd-1656f271953d', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Renta za oktobar odbijena zakupcu od depozita, a računi za oktobar su išli na teret vlasnika. U toku oktobra meseca u stanu je boravio Luka advokat'), now()
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '43afa8bc-5c84-5bd5-af7a-5b8b91764365', '795db987-07d2-515b-84cd-1656f271953d', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Proveriti da li je Jovana fakturisala rentu za decembar i račune za novembar novom zakupcu Eko Srbija'), now()
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '86ad0723-1506-5c73-9437-e7918936f18e', '795db987-07d2-515b-84cd-1656f271953d', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Jovana mailom potvrdila da je placena renta za mart 27.03.2026.'), '2026-04-02 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'cc932eb9-0821-5576-9a8b-3b493c80e8cf', '795db987-07d2-515b-84cd-1656f271953d', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Jovana mailom potvrdila da je placena renta za april 15.04.2026. kao i da su uplatili prefakturisane troskove za:
    decembar 2025 - 44.490,27 rsd
    januar 2026 - 47.727,03 rsd'), '2026-04-17 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '5d05e223-e2b1-54fe-84ed-64feccff6e60', '795db987-07d2-515b-84cd-1656f271953d', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Jovana mailom potvrdila rentu za maj da je placena i racuni za februar'), '2026-05-14 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '8aadfc77-e627-5914-8e39-300ada61455f', '795db987-07d2-515b-84cd-1656f271953d', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Jovana mailom potvrdila da je placena renta za jun, kao i racuni za mart i april'), '2026-06-17 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'c3479f0d-2c64-5940-82c2-c07aaeab24da', '795db987-07d2-515b-84cd-1656f271953d', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Jovana mailom potvrdila da je placena renta za jul'), '2026-07-30 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'e4249676-5cad-57a8-9a6d-3312d27fac23', '795db987-07d2-515b-84cd-1656f271953d', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Jovana mailom potvrdila da je placena renta za avgust'), '2026-08-04 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '31040ca5-88d1-5471-91b0-76aa824a877a', '795db987-07d2-515b-84cd-1656f271953d', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Jovana mailom potvrdila da je placena renta za sept'), '2026-09-07 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '0269f31e-aa9f-58fb-97f1-d3d7a641cb60', '992ab199-2589-5896-816a-963caadd041e', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Od iznosa 39.750 koji su zakupci bili duzni da plate za komunalije za jun, odbijen je iznos od 10.500 za Ikea policu u vesernici, tako da je placeno 250 eur'), '2025-08-12 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'f9d33e13-5d05-51ef-b5f0-092b2366352d', '992ab199-2589-5896-816a-963caadd041e', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Od iznosa od 150 eur koje je preuzeto od zakupca placeno Jovici stolaru, izrada i ugradnja ogledala u hodniku u iznosu od 150 eur, za isplatu Jovani 100 eur'), '2025-08-12 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '21729f28-7673-596c-bdbf-24ea09b55294', '992ab199-2589-5896-816a-963caadd041e', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Prilikom ugradnje ogledala je pomeren prekidac za svetlo i sad im ne radi svetlo u hodniku'), '2025-08-15 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '0f248f4d-6132-5aa0-ad62-edf4f3a1efe9', '992ab199-2589-5896-816a-963caadd041e', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Treba da se kupi i ugradi daljinsko zvonce. Sitno curenje u lavabou,popustio silikon. Zamena cevi aspiratora. Aluminijumsko fleksibilno crevo treba da se zameni. Aspirator je na filter i nema uzlaz u ventilaciju. Zele da im se zameni crevo jer se oseca. Makaze na prozoru u spavacoj sobi onemogucavaju da se zatvori. (Sonuç: Kupio je i ugradio i popravio je svetlo u hodniku usled toga sto je skinuto ogledalo i zalepljeno)'), '2025-08-15 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'f976ea06-0703-5e79-a5aa-e0eed52e88fc', '992ab199-2589-5896-816a-963caadd041e', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Dodatne police u garderoberu. (Sonuç: Ugradnja polica)'), '2025-08-15 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '42012e72-2f8f-5250-b90f-5ee95e4b4e2a', '992ab199-2589-5896-816a-963caadd041e', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Zakupac predao iznos od 1000 eur za racune za avgust i septembar, ima pretplatu 20 eur. Za klimatizaciju naplacen iznos za avgust 21.000rsd umest 10.430 rsd (Sonuç: Ima dug za avgust i septembar 82,58 eura)'), '2025-10-27 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '6a9e1cac-b114-54b6-946f-a6b49d3441a9', '992ab199-2589-5896-816a-963caadd041e', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Zakupac predao iznos od 900 eura za račune za oktobar i novembar (Sonuç: Duguje još 23 eura. Ukupan dug za avgust-novembar je 105 eura, dogvoreno da se to odbije za stolice koje će oni kupiti)'), '2025-12-25 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '02be4ab0-e0d8-55ed-b154-07139b157238', '992ab199-2589-5896-816a-963caadd041e', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Zakupac je predao iznos od 520e, za racune za decembar i dug od 83+23e'), '2026-02-24 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '1ffb1cec-fb43-5223-bab1-906bf2263db0', '992ab199-2589-5896-816a-963caadd041e', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'PROVERENO JOS JEDNOM SA Jovanom, renta je placena do 31.03.2026. Poslati im upit do kada ostaju u stanu i obavestiti ih o placanju'), '2026-03-09 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'f5442d53-d5a2-55eb-becc-9877619973fa', '992ab199-2589-5896-816a-963caadd041e', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Ksenija platila račune za januar 350 EUR (Sonuç: DUGUJE JOŠ 17 EURA)'), '2026-03-11 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '6287db6e-33ef-5d32-85ea-1e3d33a6d601', '992ab199-2589-5896-816a-963caadd041e', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Poslata oba aneksa, kao i  iznos za rentu i račune koji trebaju da plate'), '2026-03-30 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'fa5d24b1-d830-573a-8f7d-83502a4de420', '992ab199-2589-5896-816a-963caadd041e', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Poslata poruka kada im odgovara, rekla je Ksenija da ce za vikend pogledati anekse'), '2026-04-01 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'd413b1bf-3650-5f67-bbd8-c3552db4772a', '992ab199-2589-5896-816a-963caadd041e', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Ksenija slikala račun koji je domar dao zbog zamene gumice ispod sudopere, i trazila majstora za vrata od kupatila'), '2026-04-02 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'c534622f-5051-50ef-a824-7352ca126ac3', '992ab199-2589-5896-816a-963caadd041e', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Ksenija bila u kancu, donela potpisane anekse, 2000e + 400e za racune'), '2026-04-09 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '3d1ffe4d-4cf2-57bc-862f-4f91001bf1b6', '992ab199-2589-5896-816a-963caadd041e', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Pozvano je više majstora za vrata od kupatila, zabrali smo najpovoljniju opciju, dogovor je da se odradi račun na firmu i da se popravka odradi danas'), '2026-04-21 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '2b584427-9f76-584a-92b1-3b5d79cc2f73', '992ab199-2589-5896-816a-963caadd041e', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Prethodni majstor koji je trebao da nam popravi bravu je otkazao, tako da smo pozvali drugog, otisao je i zamenio bravu (Sonuç: 8000 dinara zamena i popravka brave, racun na firmu)'), '2026-04-23 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'e85556da-c658-5c27-8f02-8085a4988204', '992ab199-2589-5896-816a-963caadd041e', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Struja za mart nije stigla, stavljen iznos kao za februar'), '2026-04-29 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '72c2ae44-ef6f-55b8-917e-789cdd4a3649', '992ab199-2589-5896-816a-963caadd041e', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placeni racuni za mart i renta za maj (Sonuç: 2000eur za rentu + 400 eur za racune)'), '2026-05-05 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'ae572f97-d617-504b-8724-bfb66e4fd3c8', '992ab199-2589-5896-816a-963caadd041e', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Struja za mart je stigla, promenjen je iznos u tabeli, duguje 600 dinara, naplatiti sledeceg meseca to dugovanje'), '2026-05-07 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '63da2447-a0d1-58b3-8b86-617d97225055', '992ab199-2589-5896-816a-963caadd041e', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za jun 2000 eur + racuni za april 450 eur (Sonuç: Dala 600 din dug za struju, ostaje joj 20e za sledeci mesec pretplate)'), '2026-06-02 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '663bd23e-e1f1-53f5-89b4-46e55f8dd7a1', '992ab199-2589-5896-816a-963caadd041e', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za jul 2000 eur + racuni za maj 380 eur ( obzirom da ima pretplatu 20e racuni su 360) (Sonuç: Ksenija dala 400 eur za racune umesto 360, ostaje 40 eur za sledeci mesec)'), '2026-07-06 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '82163003-af83-50cb-bfaa-09ee49b2b931', '992ab199-2589-5896-816a-963caadd041e', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za avgust 2000 eur + racuni za maj 350 eur (Sonuç: Ksenija dala 350 eur jer je imala pretplatu 40 eur)'), '2026-08-11 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'bb0bdf03-9440-58b4-a28b-3d80aa0e2288', '992ab199-2589-5896-816a-963caadd041e', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za septembar 2000 eur + racuni za jul 442 eur (Sonuç: Jovani dato 490 eur za racune, bio je dug od 40 eur)'), '2026-09-10 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'b82449b4-4e21-56c3-bc75-c178cc1de8f0', '992ab199-2589-5896-816a-963caadd041e', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za oktobar 2000 eur + racuni za avgust 500 eur + 2000 din'), '2026-10-13 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '907dde29-1e9a-53f8-a6b6-409138c1e331', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Stanarka je pre par dana prijavila da joj ne radi usisivac,takodje i da joj ne radi prekidač za bojler (Sonuç: Angažovali smo električara i kvar u vezi sa napajanjem električne energije i prekidačem je uspešno otklonjen. Usisivač je odnet na servis i popravljen je.)'), '2025-05-27 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'cbb6fb08-3d3d-5c1b-8cba-a71509ccb229', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Margarita prethodni zakupac, ostavila je avanso iznos za racune za septembar 2025 koji u tom trenutnu jos nisu dospeli, avans je iznosio 23.100 rsd a racuni su dosli u iznosu od 24.096 (Sonuç: Internet sbb proveriti da li je placen za septembar)'), '2025-10-20 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '1b1ad5b7-6763-5e11-9822-872e7f752298', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Prilikom obilaska stana nakon izlaska zakupca lavabo u jednom od kupatila bio je naprso, a sada ta pukotina deluje jos gore, pored toga, ormaric lavaboa je potpuno raskliman I truo od vode - Potrebno je zameniti i lavabo i ormaric lavaboa (pronasla sam u Ikei komplet za 43.000 rsd, i pretpostavljam da su ruke jos oko 100 eur)
    Police u singl decijoj sobi su potpuno rasklimane, I kada se nesto stavi na njih, krive se i deluju da ce da padnu i to bi trebao neko da pricvrsti sa dodatnim drzacima (Sonuç: (cena novog TV/a 70.000 rsd plus nosac 8000 rsd, plus ruke vrvt oko 50 eur))'), '2025-09-24 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '06285f13-0d46-587e-b5d3-d5b2e4f24e2e', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Od zakupca je juce primljen iznos od 2500 eur za rentu za oktobar. (Sonuç: Jovana bi trebala da preda iznos od 130 eur za usluge majstora koji je dopremio iz Lesnine i zamenio lavabo i ormaric u kupatilu, zalepio lajsnu na tv zidu u dnevnoj sobi, izneo sa terase velike saksije sa zemljom, i pricvrstio police u sobi. - placeno)'), '2025-10-02 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '162bd35d-bae1-59c9-bdc2-51e4d216ef1f', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Kupljena su 4 nova jastučeta za garnituru u dnevnoj sobi'), now()
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '8178ea5d-da4d-5590-84d5-edbefd5465de', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Primljen iznos od 2500 za rentu i 22.000 za racune za oktobar'), '2025-12-05 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'c975f277-b6f1-5893-a93c-bcc1c9deec1f', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Stanar prijavio da mu ne radi prekidač za bojler i prekidač za svetlo u jednom kupatilu. Takođe je prijavio da mu ne radi smart sistem na televizoru ni wi-fi u spavaćoj sobi (Sonuç: Mora da se angažuje električar)'), '2026-02-11 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '297cec8e-a093-5a4a-b088-fc3189cc96d3', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Primljen iznos od 292.500 rsd za rentu za mart'), '2026-03-06 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '35415488-5f2e-56fc-8401-1db87502324c', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Primljen iznos od 83.500 rsd za racune za januar i februar (Sonuç: 7.200 dinara za mts uzeto, zamolio je da platimo)'), '2026-03-20 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '4b46a35c-50cd-5583-8edc-93c9a89f4e0c', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Poslata poruka za kiriju za april'), '2026-04-02 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '22f5d7e3-1d03-5411-8a92-a389d3c8d4f0', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena kirija za april (Sonuç: 292.500 primljeno)'), '2026-04-06 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'f7824a62-4811-5b95-a5ce-562e2706453b', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Elektricar je bio juce, promenio je prekidac, ustanovio je da bojler ne radi, a internet na tv-u ce popraviti (Sonuç: Danas ce otici majstor za bojler da ga popravi, cena iznosi 12.000 dinara, Darko ce platiti pa cemo mu odbiti taj iznos kada bude davao za troskove)'), '2026-04-24 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '7ab0aac9-9434-5350-a601-41d86d7e2fee', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Pavle elektricar popravio prekidač, svetlo (u kupatilu) i resio problem sa TV-om u spavaćoj sobi (sproveo Lan kabal do TV-a) pa sad imaju internet (Sonuç: Iznos popravki je iznosio 8.000 dinara)'), '2026-05-04 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '91d0732b-a3d6-5338-80fd-e570cc5fc9de', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Primljen iznos od 314.300 dinara, renta za maj i racuni za mart (Sonuç: Obzirom da je platio sam popravku za bojler naplaceno mu je 12 hiljada manje)'), '2026-05-06 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '45a77dda-6538-5c32-a7df-5def29878ccc', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Prekidac ne radi na kupatilu ponovo, pozvan elektricar otici ce u ponedeljak da popravi'), '2026-06-19 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '0e5314c9-5883-5e3c-a929-6f18c2ce4acf', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Popravljen prekidac, popravka je iznosila 6.800 dinara, uplaticemo Pavlu na racun, pa ce Jovana da nam da novac'), '2026-06-22 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'e573fcd1-23f6-5f1f-887f-51e67c6504cd', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Pokupljena renta za jul 2.500 eur + racuni za maj (Sonuç: Ukupno 323.800 dinara uzeto)'), '2026-07-07 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '1e96c3fa-ddbc-589f-9a60-aab634af6e90', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Pokupljena renta za avgust 2.500 eur + racuni za jun (Sonuç: Ukupno 292.500 din za rentu i 24.700 din za racune)'), '2026-08-04 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '0a0707e2-6b02-5c7a-9d4b-e511ad41c96f', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Krevet iz A bloka prebacen u ostavu 081 i 088 u Rivieru (Sonuç: Odnesena i nova garnitura za terasu i postavljena, ti troskovi su iznosili 200 eur za prenos iz emecete u stan bastenski namestaj, nakon toga kreveti iz a bloka u rivieru, bastenski set i jastuci su iznosili 29.680 dinara)'), '2026-08-18 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '2f671bbc-b921-5436-b495-517a50930921', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Pokupljena renta za septembar + racuni za jul (Sonuç: 320.000 dinara)'), '2026-09-08 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'bd607413-dd36-539f-b8ae-44cb80812137', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Pokupljena renta za oktobar + racuni za avgust'), '2026-10-14 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'e5a72b78-64ba-5002-b489-a686be9a1125', '6308167e-af32-53bb-9c22-df5efa478fa1', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Zakljucen ugovor o zakupu. Uplaceno: depozit 2300 eur i prva zakupnina 2300'), '2025-06-23 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '3dfdc675-c6de-5d7b-8021-26873a7a4aad', '6308167e-af32-53bb-9c22-df5efa478fa1', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Zakupac prijavio da ne radi usisivac. (Sonuç: Uzet usisivac iz A 5.17 i odnet u C 7.28, a pokvareni usisivac kod Natase u gepeku, treba da se nosi na servis)'), '2025-08-04 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '2724fcd4-710b-5d30-93dc-cc31769f1390', '6308167e-af32-53bb-9c22-df5efa478fa1', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Zakupac istakao zahtev da zeli draperije u obe spavace sobe (Sonuç: Biljana odobrila, narucene su draperije kod Gabrijele dana 06.08)'), '2025-08-04 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '9fc0adc2-5d03-5f61-a937-9c8bad41ad99', '6308167e-af32-53bb-9c22-df5efa478fa1', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Zakupac obavesten da treba da plati 64 eur za komunalije za deo juna'), '2025-08-05 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'c9f51a6d-abbb-52af-a982-eb30a2254f15', '6308167e-af32-53bb-9c22-df5efa478fa1', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Zakupac trazio instalaciju i kupovinu TV za spavacu sobu'), '2025-09-25 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'b746a885-4fff-575f-8f48-8b7533a95244', '6308167e-af32-53bb-9c22-df5efa478fa1', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Poručen novi televizor - 44.000 din + 2.000 din dostava'), '2025-10-02 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'f4b84af3-f67f-5ddb-9d1e-8276fc42357e', '6308167e-af32-53bb-9c22-df5efa478fa1', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Namontiran TV, Radmila sama kupila nosač, cena montaže 4.500 dinara (Sonuç: Nije trazila refundaciju za nosac za TV)'), '2025-10-20 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '5c31c091-0bf5-5670-96fa-ea08ca23be7e', '6308167e-af32-53bb-9c22-df5efa478fa1', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Jovana potvrdila: 2300 eur renta do 22.11 (novembar) + 36500 rsd za racune za septembar (racuni su 34.490,11 rsd) imala dug od 25 eur, sada duguje jos 915 rsd.'), '2025-10-27 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '00e4c869-7583-5c2e-84ba-b11e9cea25f6', '6308167e-af32-53bb-9c22-df5efa478fa1', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Platili rentu za decembar - 2.300 EUR i dali 300 EUR za račune za oktobar (Sonuç: Dali još 1000 dinara za dug iz prethodnog meseca)'), '2025-11-25 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '155dbffd-2282-5d32-b8f6-b06fbf0e9cb8', '6308167e-af32-53bb-9c22-df5efa478fa1', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Otkazali ugovor o zakupu. Iz depozita odbijeno za račune za novembar i decembar, za čišćenje stana 150 eura sanacija parketa 100 eura i renta za januar 2300 eura'), now()
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '2ef22427-4844-58ae-859b-4cfa89eb0dba', '6308167e-af32-53bb-9c22-df5efa478fa1', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Stanarka prijavila curenje bojlera. Takođe je prijavila da joj ne radi mali bojler i da je u pitanju utičnica. (Sonuç: Curenje je sanirano, pozvali smo izvođača radova jer je zgrada i dalje u garanciji. Za bojler je angažovan izvođač koji će ovih dana to da reši.)'), '2026-02-11 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '8b1b2abf-7368-575c-ba89-b7362faca593', '6308167e-af32-53bb-9c22-df5efa478fa1', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Stanarka je izbacila i predala Natasi, sve jastuke, jorgane i svu posteljinu iz stana, i to ce biti smesteno u ostavu stana 1607 BW Aqua u plavim Ikea torbama. Takodje je izbacila usisivac, ali ga nije predala nama, potrebno je da ga ona vrati prilikom isteka ugovora.'), now()
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'a25ada69-040f-52f7-85bb-52ae5702584d', '6308167e-af32-53bb-9c22-df5efa478fa1', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Stanarka je obavestena o iznosu koji treba da isplati za racune za februar'), '2026-03-25 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '8b945349-28a3-5d6c-ab1c-d427f9d17f79', '6308167e-af32-53bb-9c22-df5efa478fa1', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Sara je rekla da će danas ili sutra da ostavi novac za račune'), '2026-03-30 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '55e0ab48-e49b-53f8-8b53-69096d53220c', '6308167e-af32-53bb-9c22-df5efa478fa1', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Preuzet iznos za racune za februar 500 EUR + 2.000 RSD'), '2026-04-01 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '5c6e6d25-93e8-53e9-99e6-e9dfdf10a005', '6308167e-af32-53bb-9c22-df5efa478fa1', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Nataša je uzela usisivač od Sare jer ga ona ne koristi, pa je odnela Ani u Terraces 104 jer se njen pokvario'), '2026-04-21 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'd203283b-3fa6-5a70-8681-6c7646de1f75', '6308167e-af32-53bb-9c22-df5efa478fa1', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Preuzet iznos za racune za mart 53.500 dinara'), '2026-05-06 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '12fe127e-cfe2-5357-aae6-0542dbabab83', '6308167e-af32-53bb-9c22-df5efa478fa1', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Sara preuzela iznos od 16.800 eur za rente koje je platila unapred obzirom da je raskinula ugovor o zakupu (Sonuç: RACUNI ZA APRIL PLACENI OD DEPOZITA KOJI SE ZADRZAVA ZA POKRIVANJE TROSKOVA)'), '2026-06-02 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '32f63c26-b253-5862-b940-fa69be037fe7', '6308167e-af32-53bb-9c22-df5efa478fa1', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Cistacica je bila i detaljno ocistil stan, kao i covek za dubinsko pranje namestaja'), '2026-06-16 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '8862338f-cda6-5615-a566-e95ab8cec7fc', '6308167e-af32-53bb-9c22-df5efa478fa1', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Useljeni novi stanari, placena renta za period od 24.06.-23.06.2026.'), '2026-06-24 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'e08627e1-52d0-52b3-a158-ba25d9f70773', '6308167e-af32-53bb-9c22-df5efa478fa1', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Odnet novim stanarima jos jedan kljuc sa tagom, sada su kod njih 3 kljuca, dva sa tagom i jedan bez'), '2026-06-28 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'ee033901-f578-5647-afb5-321f9b19e70c', '6308167e-af32-53bb-9c22-df5efa478fa1', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za avgust i septembar 4.000 eur (Sonuç: Za period od 24.07.-23.09.2026.)'), '2026-07-29 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '9f42360d-609c-54c2-a850-852d79962583', '6308167e-af32-53bb-9c22-df5efa478fa1', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placeni racuni za jul, dato 320 eur i 200 din'), '2026-08-28 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '50533bdf-8065-5904-a98a-34e2b0c10e7a', '6308167e-af32-53bb-9c22-df5efa478fa1', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Posteljine koje su bile u firmi u dve Ikea plavim kesama su prebacene u ostavu broj 081 u Rivieri'), '2026-09-22 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '5a767f75-4526-5e62-b3fc-7d1cef77265a', '6308167e-af32-53bb-9c22-df5efa478fa1', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za oktobar i novembar ( 24.09.-23.11.) kao i racuni za avgust u iznosu od 278 eur (Sonuç: Takodje platili su racune za period od 7 dana u junu kada su se uselili ( 70 eura ))'), '2026-09-25 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '1bee87c1-0904-5a17-bfc2-3c7339810498', '47013784-dd68-567f-942a-90c43141820a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Uselili su se short term zakupci na period od 14.06-01.07 i platili iznos od 3400 eur'), '2025-06-14 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'cb8aeb4d-8bf0-58a7-a5b3-405e9d795d93', '47013784-dd68-567f-942a-90c43141820a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Potpisan ugovor o zakupu. Zakupac uplatio depozit u iznosu od 3200 eur, 1600 eur za period 22.07.-22.08 (kirija sa 50% popusta) i 930 eur za period od 23.08-31.08. (deo kirije za 9 dana avgusta po punoj ceni zakupnine srazmerno broju dana)'), '2025-07-22 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'dcbbbace-6bbd-50cd-9e0e-2c945dcc22df', '47013784-dd68-567f-942a-90c43141820a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Izneti su singl kreveti iz sobe i preneti u ostavu br.12 na -1, u B kulu BW Residences'), '2025-07-23 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'a58a12bc-3352-5f5d-a023-eb904af71aca', '47013784-dd68-567f-942a-90c43141820a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Gabrijela nas je obavestila da masina za sudje izlazi iz lezista i da treba da se pricvrsti, takodje i da u tom stanu nema usisivaca.'), '2025-07-23 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '5f15fbe2-3c38-581f-b4fa-f9774341dd81', '47013784-dd68-567f-942a-90c43141820a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Zakupac istakao zahtev da o svom trosku skine luster iz dnevne sobe i da stavi svoj, rekao da ce pri izlasku iz stana da vrati u prvobitno stanje'), '2025-08-05 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'bde33dc6-7dc8-5c00-bc6d-0b105990722b', '47013784-dd68-567f-942a-90c43141820a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Zakupac dao tri mesečne kirije unapred, za oktobar, novembar i decembar 2025. god. (Sonuç: Platio racune za avgust (racuni iznose 40.075,79 rsd / 343 eur) tako da zakupac ima pretplatu 57 eur + stara pretplata 14 eur)'), '2025-10-06 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'cd1b6585-1240-5048-ae0a-5e77af2f0334', '47013784-dd68-567f-942a-90c43141820a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Dao novac za račune za septembar, oktobar i novembar (Sonuç: Ukupan iznos računa 135.8800 din, on je dao 140.000 din tako da ima pretplatu 4.120 din)'), '2025-12-19 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '6618af0e-79c1-5899-9e08-79dd88626d60', '47013784-dd68-567f-942a-90c43141820a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', '6700 renta jan i feb i 300 e avans za račune'), now()
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '434b1e9e-d790-5ed5-91ca-28a34e0fae11', '47013784-dd68-567f-942a-90c43141820a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Zakupac dao rentu za mart 3200 e i novac za racune za januar (Sonuç: Dao 50e vise tako da ima pretplatu + pretplata iz prethodnog perioda 331e)'), '2026-02-27 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'd58f3b94-cc74-5e65-a720-c66de8609b69', '47013784-dd68-567f-942a-90c43141820a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Poslata poruka za placanje rente za april i racune za februar'), '2026-04-02 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '7f9b3f1b-6f4f-57bb-9040-1806d1804560', '47013784-dd68-567f-942a-90c43141820a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena kirija za april 3200 + racuni za februar 700e (Sonuç: Dao 2.140 dinara vise + pretplata iz prethodnog perioda 381e)'), '2026-04-06 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '5edc3901-1c46-517d-8120-b5b99eb81776', '47013784-dd68-567f-942a-90c43141820a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena kirija za maj 3200 + racuni za mart 74.000 dinara'), '2026-05-04 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '9fe6e57d-2309-5bc9-8d97-ec6e5485b909', '47013784-dd68-567f-942a-90c43141820a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena kirija za maj 3200 + racuni za mart 600 eur + 2.000 dinara (Sonuç: Dao 1000 dinara vise)'), '2026-06-03 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '18433b1f-dd4f-57e2-b179-35ad94d78c33', '47013784-dd68-567f-942a-90c43141820a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Rade se pozalio da ne radi interfon, majstor ce doci da popravi jer je zgrada u garanciji'), '2026-06-09 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '6bb508b4-bd32-51cc-b219-e04d43b7c0bf', '47013784-dd68-567f-942a-90c43141820a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Rade platio rentu za jul 3.200 eur + dao novac za racune za maj 570 eur'), '2026-07-01 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'ec95ac6a-dbe4-517a-ac23-d0a2afb7e3a9', '47013784-dd68-567f-942a-90c43141820a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Rade platio rentu za avgust, septembar i oktobar 9.600 eur + novac za racune za jun 470 eur'), '2026-08-04 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '7499fd53-0e9d-5c1a-a2ab-3e3215f7a4d0', '47013784-dd68-567f-942a-90c43141820a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placeni racuni za jul u iznosu od 56.200 dinara'), '2026-09-10 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'e082dc62-58ad-5965-bee2-bedb00dd0678', '47013784-dd68-567f-942a-90c43141820a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placeni racuni za avgust 500 eur + 1000 dinara'), '2026-10-07 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '88fc6c3c-6e6e-5464-b45c-70fb27d8c516', '64ba78b5-a1b9-5157-9070-5481c640b124', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Zakupac je tražio dve komode pored kreveta,prostirke za kupatilo i kantu u kupatilu. Trazio je cediljku za tanjire i escajg,takodje stalak za ubrus,slanik i krpe za kuhinju. Prostirke ispred stana i na ulazu u stan je tražio. Za dnevni boravak želi komodu. (Sonuç: Nabavili smo nocne stocice.)'), '2025-06-02 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '365a563b-8309-5dba-a3e6-eed422c29aca', '64ba78b5-a1b9-5157-9070-5481c640b124', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'zakupac u januaru 2026 godine, platio zakup za period 25.12.2025 do 24.01.2026 i platio racune za novembar 21.000 rsd'), now()
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '957eeeca-3def-5472-97e0-53e62492d18e', '64ba78b5-a1b9-5157-9070-5481c640b124', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Branko dao za račune za januar 26.000 dinara i rentu za mart 1.400 dolara (1.200 eura) (Sonuç: Predato Jovani)'), '2026-03-11 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'ee288bc1-db9f-52b0-809a-11751dc27bb1', '64ba78b5-a1b9-5157-9070-5481c640b124', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Zakupac trazi snizenje cene rente sa 1200 na 1000 eur uz obrazlozenje da je nasao jeftiniji stan. Poslat mail Jovani za konsultaciju'), '2026-03-16 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '56eda1ad-5573-566f-9aaa-c414478a1658', '64ba78b5-a1b9-5157-9070-5481c640b124', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Zakupac platio rentu 1000 EUR + racune za februar 27.500 dinara (Sonuç: Predato Jovani)'), '2026-03-27 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '435fb5a9-bdff-52ec-ad42-6dd32889faf4', '64ba78b5-a1b9-5157-9070-5481c640b124', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Odradjen aneks za smanjenje rente sa 1200 na 1000, dati mu da potpise kada se sledeci put budemo nalazili za novac'), '2026-03-30 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '2125f9d3-7adf-52bd-b29f-bd81006ebfb1', '64ba78b5-a1b9-5157-9070-5481c640b124', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Branko je rekao da ce u sredu doneti novac jer je na putu'), '2026-04-26 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '9e54bd3d-5740-54c6-a905-8e234bd6dbac', '64ba78b5-a1b9-5157-9070-5481c640b124', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za period od 25.04. - 24.05.2026 (Sonuç: 1000 eur renta plus 25.530 dinara racuni za mart)'), '2026-04-28 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'c0cdd045-3fce-52c0-bddc-2b02e7034ae5', '64ba78b5-a1b9-5157-9070-5481c640b124', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za period od 25.05. - 24.06.2026 (Sonuç: 1000 eur renta + 24.800 dinara racuni za april)'), '2026-05-29 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'ea4cb5b0-553a-5839-b595-4b1a24c215db', '64ba78b5-a1b9-5157-9070-5481c640b124', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Zakupac je zatrazio komodu i televizor za spavacu sobu'), '2026-05-29 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '8c770142-9c7c-51de-bbdd-dae134619b03', '64ba78b5-a1b9-5157-9070-5481c640b124', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Porucena komoda iz jyska kao i televizor za spavacu sobu (Sonuç: Poruceno je sa kartice Asserie tako da je automatski placeno)'), '2026-06-24 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'a091e04c-2bf1-5a64-98a3-9b75b5b7fcd7', '64ba78b5-a1b9-5157-9070-5481c640b124', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Preuzeta renta za period od 25.06.-24.07 100 eur + novac za racune 24.800 din (Sonuç: Za racune je dao 2.500 manje)'), '2026-06-29 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '9a9ffca3-3195-5fcd-972e-723cf611aacc', '64ba78b5-a1b9-5157-9070-5481c640b124', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Nakon nestanka struje u stanu, rerna nije radila, danas je bio ovlasceni serviser i popravio rernu (Sonuç: Obzirom da je u garanciji rerna, nije bilo naplate)'), '2026-07-08 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'f6baacc4-f42a-5f10-b728-6d5e96b86044', '64ba78b5-a1b9-5157-9070-5481c640b124', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Preuzeta renta za period od 25.07.-24.08 (Sonuç: 1000 eur renta + 24.600 din ( uracunat i dug od 2.500 din ))'), '2026-08-11 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '3440f25c-0f1d-5550-a91b-545e4344f6e5', '64ba78b5-a1b9-5157-9070-5481c640b124', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Preuzeta renta za period 25.08.-24.09. (Sonuç: 1000 eur renta + 21.300 racuni jul)'), '2026-09-08 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '3afa693b-f8b7-5da6-a596-c65419ebf037', '64ba78b5-a1b9-5157-9070-5481c640b124', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Preuzeta renta za period od 25.09.-24.10. (Sonuç: 1000 eur renta + 21.00 dinara racuni avgust)'), '2026-10-08 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '2a375744-66f3-56ac-a013-21ed8791a1b5', 'a9a4d27b-b3d3-5572-a0f4-0ab22a7b32d6', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Zakljucen ugovor o zakupu. Uplaceno: depozit 2200 eur, 410 eur avansno za racune i prva zakupnina za deo juna 1450 eur 10.06.-30.06'), '2025-06-10 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '153bb668-ac03-5d94-9080-f32d0e3a6b1a', 'a9a4d27b-b3d3-5572-a0f4-0ab22a7b32d6', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Zakupac je istakao sledeće primedbe: Uklanjanje tapeta. Zatvoriti uticnice u glavnoj spavacoj sobi. Double bed u gostinjskoj sobi i manji TV u istoj sobi. Na ulazu u ormaru fale usporivači. Push sistem za garderober fali u glavnoj spavacoj sobi i usporivaci. Problem sa internetom. Namestaj za terasu. Pribor za jelo i kuhinjska oprema. Takodje fale peškiri,ogrtači,pegla i usisivač. Tražila je sef. (Sonuç: Obaveštena je da zahtev za internet mora sama da podnese. Kupljen joj je sef. Nabavili smo joj double bed za gostinjsku sobu. Nabavili smo joj TV za gostinjsku sobu. Nabavili smo peglu.)'), '2025-06-10 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '80c189f0-0fee-53ce-8a32-2c1a053d5256', 'a9a4d27b-b3d3-5572-a0f4-0ab22a7b32d6', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Zakupac je istakao sledeće primedbe:Nema usporivač ispod sudopere. Orman na ulazu udara. U gostinjskoj sobi vire šrafovi. Nema stoper za vrata u spavaćoj sobi. Fali kanta za djubre,sušač za veš,aparat za kafu i toster. Zakupac je trazio otvorene police za cipele u master sobi pored ormana. (Sonuç: Nameštena joj je kanta i ugradjena joj je u gostinjskoj sobi u ormanu. Električar je došao za prekidače i ugradio usporivač na ulazu. Isporucene su joj otvorene police za cipele u master sobi. Nabavili smo zakupcu toster,aparat za kafu.                                                                                                             •        Toster okvirna cena 100 eur 
    •        Kafe aparat okvirna cena 100 eur 
    •        Žica-sušač za veš okvirna cena 50 eur 
    •        Sef - okvirna cena 120 eur 
    •        Mali TV za gostinsku sobu (okvirno 300 eur))'), '2025-06-11 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '6205ee82-98b6-549f-93e0-e0bf1f91eac2', 'a9a4d27b-b3d3-5572-a0f4-0ab22a7b32d6', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Milica dala rentu za novembar, dala je 2.200 EUR, kirija joj je 1.150 EUR (Sonuç: Ostala dužna da plati račune za septembar u iznosu od 27.906,89 din (ali ima pretplatu 35 EUR))'), '2025-11-14 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '101cbc2d-e4f2-5229-920e-66ff45f781d3', 'a9a4d27b-b3d3-5572-a0f4-0ab22a7b32d6', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Milica je donela 25.02. iznos od 79.100 za racune za novembar i decembar 2025'), now()
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'cea9f67b-8a19-5844-9e07-df1af894ab8e', 'a9a4d27b-b3d3-5572-a0f4-0ab22a7b32d6', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Duguje racune za januar i februar kao i rentu za januar i februar 2026 (Sonuç: Ukupno 4300 eur plus racuni januar Дин. 59,821.84 plus za februar)'), now()
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '5c1ecbd2-c3cf-576f-be77-1fa3af1d96e9', 'a9a4d27b-b3d3-5572-a0f4-0ab22a7b32d6', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Opomene su isle svaki drugi dan pocev od 10.01.2026'), now()
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'd0ff6a32-2853-5bdc-ab46-085268e87154', 'a9a4d27b-b3d3-5572-a0f4-0ab22a7b32d6', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Ukupno dugovanje pristiglo do sad 4300 eur plus racuni za januar'), now()
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '8412d0ad-0e6f-57b7-abf3-859111260288', 'a9a4d27b-b3d3-5572-a0f4-0ab22a7b32d6', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Milica zvala i obavestila da ce isplatiti dug u petak 20.03.2026'), '2026-03-17 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '1d987444-3fe6-5b54-996b-89f133ea0f20', 'a9a4d27b-b3d3-5572-a0f4-0ab22a7b32d6', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Usao novi zakupac, dala prvu rentu u iznosu od 2000 EUR + 3000 EUR depozit'), '2026-04-04 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '1e19324b-9c24-541a-aa5c-768ab7bf0849', 'a9a4d27b-b3d3-5572-a0f4-0ab22a7b32d6', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Slavica je zamolila da se dubinski opere nameštaj u dnevnoj sobi, kao i tepisi jer su dosta pokupili miris cigara od prošlog zakupca. (Sonuç: Dubinsko pranje nameštaja je odradjeno, iznosilo je 4.000 dinara i plaćeno je u kešu. Tepisi su takodje odneti, za njih je odradjen predračun, iznos je 10.206 dinara, poslato je Jovani da plati)'), '2026-04-29 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '58d6f044-6bf1-51dd-834f-e7173f650e36', 'a9a4d27b-b3d3-5572-a0f4-0ab22a7b32d6', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Preuzeta renta za 3 meseca unapred, za maj, jun i jul (Sonuç: 6.000 eur)'), '2026-05-06 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'af449469-6afa-52bb-a3f3-3cedba32bd34', 'a9a4d27b-b3d3-5572-a0f4-0ab22a7b32d6', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Slavici ostavljen kljuc od stana na Terraces-u, zatrazila je jos jedan jer joj je dat samo jedan kljuc'), '2026-05-08 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '2c5e0be5-0892-5f1b-ab53-51771b69782e', 'a9a4d27b-b3d3-5572-a0f4-0ab22a7b32d6', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Slavica uplatila 34.000 za racune za april'), '2026-06-03 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '1b7355e2-708c-55fd-9175-2883d9290af8', 'a9a4d27b-b3d3-5572-a0f4-0ab22a7b32d6', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placeni racuni za maj u iznosu od 40.250 dinara'), '2026-07-03 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '3e8d5626-1e2f-589f-a596-34b1d6766eb2', 'a9a4d27b-b3d3-5572-a0f4-0ab22a7b32d6', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za avgust 2.000 eur + racuni za jun u iznosu od 31.000 din'), '2026-08-06 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '2320fddb-7f8c-5fde-825f-70f6b39c8593', 'a9a4d27b-b3d3-5572-a0f4-0ab22a7b32d6', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za septembar 2.000 eur + racuni za jul u iznosu od 32.400 rsd'), '2026-09-08 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'ca4970eb-aaff-54f0-9057-f6f2d3248ac4', 'a9a4d27b-b3d3-5572-a0f4-0ab22a7b32d6', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za oktobar 2.000 eur + racuni za avgust 32.000 + 5 eur'), '2026-10-13 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'e0fa436a-4766-52a0-bc17-80145d427ab7', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Platila račune za oktobar - dala 42.000 dinara'), '2025-11-21 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '2855e88f-c0c6-574e-b1f7-d8f0c739da11', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Platila rentu za decembar 2.450 EUR i dala još 250 EUR više - ukupno dala 2.700 EUR (Sonuç: 250 EUR ostaviti pa platiti sledeće račune)'), '2025-12-12 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '7a75d385-6554-578a-8c1e-6b46464ad0ef', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Platila rentu za januar i račune za novembar, u to ulazi i 250 EUR od pretplate od prethodnog meseca (Sonuç: Ima pretplatu nekih 13 EUR)'), '2026-01-09 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'aa7b797c-a07d-5581-971a-1d75a7fa1371', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Platila rentu za januar i račune za decembar (Sonuç: Nije dala tačan iznos, fali 212 eura ili 25.000 dinara. Dala je 149.500. dinara i 505 eura)'), '2026-02-11 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'e15ff24d-c1ac-53b8-8dc8-47f6d0d0e33c', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Maja dala 212 eura koji su falili'), '2026-02-18 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'c1f1468f-8251-50bf-9d79-162cdccf75a4', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Platila rentu za mart 2.450 EUR i dala 870 eur za racune (Sonuç: Dala je 90e vise tako da je u pretplati)'), '2026-03-06 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '6aed140b-e056-5977-9705-9b4f1467955f', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za april 2.450 EUR i dala 70.000 dinara za racune (Sonuç: Pretplata od proslog puta 90e)'), '2026-04-06 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '8ebc975b-b5b2-5bfd-acce-78d9362e4c47', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za maj 2.450 EUR + 600 eur za racune za mart'), '2026-05-06 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'f0f5a10d-061c-51da-8506-3b5c5d935829', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za jun + racuni za april (Sonuç: Dato je 1000 eur + 229.500 dinara, ja sam iz pretplate dodala 20 eur jer su dali toliko manje za racune, sada im ostaje pretplata od 70 eur)'), '2026-06-05 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '7db9eea9-3d50-5108-b562-bccfc9d8528a', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za jul + racuni za maj (Sonuç: Dato je 2.350  eur + 72000 dinara, dodato 20 eur iz pretplate)'), '2026-07-08 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'bbf14caf-74c2-5df8-bcab-571315db97de', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za avgust  + racuni za jun (Sonuç: 1.000 eur + 170.000 din renta + 53.520 din za racune)'), '2026-08-07 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'a61b0644-0d9c-58ec-9461-5638a143fe61', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za septembar + racuni za jul (Sonuç: 2.450 eur + 55.000 din)'), '2026-09-09 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '24038455-303d-5864-80fa-80fb68eb4d3b', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za oktobar + racuni za avgust (Sonuç: 2450 eur + 56000 dinara)'), '2026-10-13 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'e7dfafdd-d39a-549e-9822-ea3f73627e28', 'cbb8caa3-60d2-5462-b18d-deb10d72e925', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Prozori u podrumu ne rade dobro, ulazi voda kada je kiša. Vlaga u spavaćoj sobi. Problem sa bazenom- smanjeju se nivo vode.'), now()
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '7697523c-72db-5e4c-95ac-de8405e92315', 'cbb8caa3-60d2-5462-b18d-deb10d72e925', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Zakupac je 1.09.2025. nagovestio da izlazi zaključno sa 30.09. 2025.'), now()
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '45a0b80f-70a6-5105-9e5f-20bf9f0b3209', 'cbb8caa3-60d2-5462-b18d-deb10d72e925', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Novi zakupac je zatražio ugradnju i zidanje djakuzija u podrumu u iznosu od 10.000 EUR. Pokrivka za bazen 1.800 EUR u našem trošku.'), now()
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '6632a5fe-3095-50f0-8960-8aaac737fec6', 'cbb8caa3-60d2-5462-b18d-deb10d72e925', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Zakupci su predali iznos od 9000 eur za depozit (dve kirije), a u subotu ili nedelju radimo primopredaju sa njima kada ce mi predati I iznos za prvu rentu (treba da im se preracuna za period od 05.10 pa do kraja meseca, po mom proracunu to je 3920 EUR) (Sonuç: Za Sremcicu treba Jovana da preda iznos od 100 eur koji bi trebalo da odbije od depozita prethodnog zakupca za čišćenje, osim toga od tog depozita treba da odbijemo I iznos za racune kada dobijemo od Nikole Korde taj iznos. Za hemiju za ciscenje donela racun 1800 dinara, taj novac mi je vec dala. Za Sremcicu mi je Jovana predala iznos od 1722 eur koji sam predala bazendziji za pokrivku za bazen (priznanica u prilogu, a original cu preuzeti kad ga vidim))'), '2025-10-02 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'acc9176c-1c95-5b90-9a1a-b4c715badc95', 'cbb8caa3-60d2-5462-b18d-deb10d72e925', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Išlo se u Sremčicu da se uzme renta. Danas se takođe popravljaju radijatori u kupatilima i garaži i podešava se struja, tj majstori i električari podešavaju da struja i wi fi rade u svim sobama'), '2025-11-04 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '0820ef77-f04b-58a5-9d6e-34656d44ea37', 'cbb8caa3-60d2-5462-b18d-deb10d72e925', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Proveriti da li je Nikola kupio poštansko sanduče za Sremčicu'), now()
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'de4870e8-197d-5cf3-a9a2-2952fdbe2326', 'cbb8caa3-60d2-5462-b18d-deb10d72e925', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Marco doneo rentu za januar 4.500 EUR'), '2026-01-12 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '1acd3cd2-7e00-5945-a9be-2665797b57f5', 'cbb8caa3-60d2-5462-b18d-deb10d72e925', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Dali rentu za februar - 4.500 EUR'), '2026-02-18 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'cf2132c2-bbb7-5134-a10d-012bbb732fab', 'cbb8caa3-60d2-5462-b18d-deb10d72e925', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Poslat im je podsetnik za placanje rente i uputstvo za samoocitavanje brojila.'), '2026-03-09 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'e9408e6f-9ad9-5ea5-8724-bdb425d1069b', 'cbb8caa3-60d2-5462-b18d-deb10d72e925', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za mart 4.500 EUR'), '2026-03-16 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'aee4adc2-0023-53ce-bf73-c82b4a74a4d7', 'cbb8caa3-60d2-5462-b18d-deb10d72e925', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Poslat mail za placanje rente'), '2026-04-02 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'e783cdd0-64ab-5937-a6c0-8493a3245ab1', 'cbb8caa3-60d2-5462-b18d-deb10d72e925', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Poslata poruka na wa, nije odgovorio, nakon toga se Natasa cula sa Markom, rekao je u cetvrtak da se vidimo za rentu'), '2026-04-06 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'd097d0d7-f880-5e29-992c-afa3a84b2a18', 'cbb8caa3-60d2-5462-b18d-deb10d72e925', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Pokupljena renta za maj u iznosu od 4.500 eur'), '2026-05-06 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '9f6ad648-2e57-562c-8e77-14ffbb6731d3', 'cbb8caa3-60d2-5462-b18d-deb10d72e925', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Pokupljena renta za jun u iznosu od 4.500 eur'), '2026-06-05 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '9d25b940-b023-5357-95d4-70c6a06ee9dc', 'cbb8caa3-60d2-5462-b18d-deb10d72e925', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Odradjeno kosenje trave i ocupavanje trave i taj trosak je iznosio 150 eur'), '2026-09-29 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '12368a3a-1111-52e5-a5f8-8ab8446efc20', 'cbb8caa3-60d2-5462-b18d-deb10d72e925', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Novi zakupci dali jedan depozit u iznosu od 3.900 EUR'), '2026-10-01 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '2d366d8e-8bff-5754-a5f2-dc62802200e0', 'cbb8caa3-60d2-5462-b18d-deb10d72e925', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Dali deo depozita u iznosu od 1.700 EUR i dali kiriju u isnosu od 3.900 EUR'), '2026-10-02 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'e3c27e03-a946-5f51-8e51-da6b79b8bcb5', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Platili rentu za 3 meseca unapred'), '2026-01-11 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '0884ee6d-a135-5cfd-8b91-45e35a95b59a', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Plaćeni računi za decembar'), '2026-01-15 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'b837c65a-6e4d-511e-a867-e4ed19c2ca56', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Pre ngo što su se zakupci uselili u stan, organizovano je i plaćeno detaljno čišćenje stana'), now()
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'bb819a79-f0ba-5b23-a6b9-b430257a7715', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Zakupci prijavili da im se pokvarila mašina za pranje veša (mašina nije u garanciji više) (Sonuç: Kvar je prijavljen servisu za popravku mašine)'), '2026-02-16 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'b2b1ba97-b8c1-5dc4-bb68-ea32a77a0c10', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Serviseri su bili da poprave masinu, promenjena je guma i provereno je da masina ne ispusta vodu (Sonuç: Placeno je na licu mesta 10.000)'), '2026-02-19 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '3af41c77-944c-5860-bf2d-e4563d48af2d', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Pokupljen racun za struju, racun iznosi 4843,22, ali je u pretplati 2814,78'), '2026-03-10 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '042ff2d0-c57e-561a-8487-9b83271892ec', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placeni racuni za februar (Sonuç: Razmenjeno 750e za racune)'), '2026-03-13 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '7021875b-c1b1-5f50-9853-9f48bd96bfd9', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Platio rentu jos 3 meseca unapred (Sonuç: 12.000 EUR)'), '2026-04-06 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '12c0e99e-31bf-5f97-9eb9-caa416e342f5', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placeni racuni za mart ( bez struje i mts) u iznosu od 78.918,02 (Sonuç: Razmenjeno je 690 eur)'), '2026-04-20 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '1d9fdce6-9baa-503f-abdd-391a6af9128d', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Stigao je racun za MTS uvecan, zvali smo i dobili povratnu informaciju kako se na jednom racunu nalazi racun i za Hercegovacku i za adresu gde vlasnik zivi'), '2026-04-21 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'a2dbad14-d3d1-5ff5-9c7e-9d2dd82bde3e', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Razmenjeno 100 eur da bi se platio MTS racun (Sonuç: Ostao kusur 1000 dinara)'), '2026-05-08 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'b319f9f0-c98c-528f-904f-075caa65b6bc', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Razmenjeno je 850 eur od agencijske provizije za racune i placeni svi racuni (Sonuç: Dobijeno 99.025 dinara, kusur 2.290 dinara)'), '2026-05-21 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '2698d24b-4410-5f32-843f-19d06a3fa616', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placeni racuni za maj u iznosu od 88.708,52 dinara'), '2026-06-26 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '55ecdb5c-55ee-5726-a7df-834691d7bdd6', '500002db-410a-5fc6-b10f-1cdd119ed20a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Stan je detaljno sredjen i ociscen, odradjeno je dubinsko ciscenje namestaja, izbacene stvari u tri kutije koje su stavljene u ostavu od Aque 1807. Takodje, postavljen je alarm na ulazna vrata, svi računi su skenirani i prosledjeni Jovani (Sonuç: Troskovi su iznosili: - 8.000 dinara za iznosenje stvari                          - 3.500 dinara dubinsko ciscenje    - 5.577.30 dinara jastuci i jorgan)'), now()
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'bec9c792-3592-520b-bbc6-10f9c9800d89', '500002db-410a-5fc6-b10f-1cdd119ed20a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Primopredaja kljuceva i useljenje novih zakupaca'), '2026-06-10 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '9185627f-a778-5643-89d8-fa45196eca1c', '500002db-410a-5fc6-b10f-1cdd119ed20a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta jul u iznosu od 1.300 eur'), '2026-07-06 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '4ed58a07-5be1-5128-b251-69ebdb971a45', '500002db-410a-5fc6-b10f-1cdd119ed20a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Zakupac se pozalio kako prskalice prskaju umesto na povrsinu trave, prskaju po terasi, poslat je mail Beogradu na vodi, kao i Facility pointu, i pozvan je upravnik zgrade, cekamo majstore'), '2026-07-07 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '8e216a1a-32a8-5003-8391-4814976171b6', '500002db-410a-5fc6-b10f-1cdd119ed20a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Pokupljena renta za avgust, kao i novac za racune za period od 10.06. - 30.06 (Sonuç: 1300 eur renta + 24400 din za racune)'), '2026-08-05 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '519f1c48-37b4-5174-9c4d-c8f9be6daf86', '500002db-410a-5fc6-b10f-1cdd119ed20a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Pokupljena renta za septembar, kao i novac za racune za jul (Sonuç: 1300 eur + 30.270 din)'), '2026-09-08 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '527c7357-5a0a-53e1-9e2c-4f4560367046', '500002db-410a-5fc6-b10f-1cdd119ed20a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Pokupljena renta za oktobar i racuni za avgust (Sonuç: 1300 eur renta + 240 eur racuni)'), '2026-10-07 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '1f16de94-c632-5ed3-ac10-84919cf73d26', '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Novi zakupac je pri ulasku u stan platio depozit u iznosu od 3.500 eur i prvu rentu u iznosu od 2.500 (Sonuç: Ovu rentu cemo racunati kao rentu za jun, dok je 10.06.2026. platio 1695 eur i to ce biti renta za period od 21 dan u maju tj od 11.05.-31.05.)'), '2026-05-10 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '7572ecb4-30f1-50b3-8999-c2b3be0eeee6', '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Platio rentu za period od 21 dan u maju, dao je 200.000 dinara'), '2026-06-10 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'd515ff61-f919-5729-aa55-f41131b49d96', '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Zakupac prijavio problem - ne radi mali bojler i odredjena svetla (Sonuç: Cekamo da posalje mail sa objasnjenjem kvara)'), now()
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '6c43379f-11f6-514a-b96d-6992a1faada0', '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za jul 2.500 eur + racuni za maj u iznosu od 29.800 dinara'), '2026-07-01 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'f7cadbac-0e25-5450-b4e0-0a5da4cf9797', '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za avgust 2.500 eur + racuni za jun u iznosu od 59.700 dinara (Sonuç: Takodje dodao je 8.600 za info stan u maju)'), '2026-08-03 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'd50c6112-a786-5091-80fd-98feec884903', '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za septembar 2.500 eur + racuni za jul 58.700 dinara'), '2026-09-02 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'd20a1b73-f3f5-580a-85fe-ffd50af8b0d4', '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za oktobar 2.500 eur + racuni za avgust 60.000 dinara (Sonuç: 352.200 dinara dato)'), '2026-10-13 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'a5532ddb-624d-5c52-b70f-bf4b95f7742e', '964b18b7-4c64-54a1-b9ee-35f5ad7df0ba', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena i prva renta i depozit, predato Jovani'), '2026-08-05 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'aebb7cdb-3982-5ca0-8d09-0a0ab322c472', '964b18b7-4c64-54a1-b9ee-35f5ad7df0ba', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za septembar i oktobar u iznosu od 5.600 eur'), '2026-08-01 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '62988b16-842e-5dbd-a405-c3793cc77f20', 'd97b99c6-9b85-56ba-82fd-d4349b846268', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Od novih zakupaca pokupljen depozit u iznosu od 1.000 eur i predat danas jovani'), '2026-08-05 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '8c90b7c0-1f89-5063-b198-0e8644d54457', 'd97b99c6-9b85-56ba-82fd-d4349b846268', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Preuzet ostatak depozita 5700 eur kao i renta za period od 11.08.-31.08. 2.270 eur (Sonuç: Dali ukupno 8.100 eur, ostaje pretplata 30 eura)'), '2026-08-11 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '0916e470-0953-58c6-807c-b4df57105c8d', 'd97b99c6-9b85-56ba-82fd-d4349b846268', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Masina za susenje iz 303 prebacena u 2301, a iz 2301 u 303'), now()
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '3f7e9a66-1589-5ae0-8204-7553d856e767', 'd97b99c6-9b85-56ba-82fd-d4349b846268', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za septembar u iznosu od 3500 eur ( dali 3.470 eur i imaju pretplatu 30e od proslog meseca'), '2026-09-01 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'de6bb457-6218-5f59-9a44-b25925f3e852', 'd97b99c6-9b85-56ba-82fd-d4349b846268', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za oktobar u iznosu od 3350 eur (Sonuç: Otkazali su drugo pm, tako da je sada renta 3.350 eur)'), '2026-10-01 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'a0fab898-9837-5a19-a6ef-4e3dc222570b', '9c88e542-8da5-5fe4-a661-111e2e059b1a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Useljeni novi stanari, placena prva renta  i depozit u visini od 3.900 eur (Sonuç: Predato Jovani)'), '2026-08-01 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '15f9e0f2-c20f-5aa1-8967-c19fc812587c', '9c88e542-8da5-5fe4-a661-111e2e059b1a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za septembar u iznosu od 3.900 eur'), '2026-09-01 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'cc9adfbc-b5d2-53e3-a71e-5b72e46fd6bb', '9c88e542-8da5-5fe4-a661-111e2e059b1a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za oktobar u iznosu od 3.900 eur'), '2026-10-01 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '500cfc41-c6f6-5cac-922b-25017564532b', '2e42fd7e-21e3-56d5-ad1c-4a3b7b76147b', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Useljeni novi zakupci u stan, placena renta za sepembar, period od 15.09. -  30.09. u iznosu od 1.785 eur + renta za oktobar u iznosu od 3350 eur (Sonuç: Takodje, placen depozit u visini dve zakupnine 6.700 eur)'), '2026-09-15 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '635960b4-f0d0-5409-ac9c-e183b46ddf98', '2e42fd7e-21e3-56d5-ad1c-4a3b7b76147b', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Svo posudje, serpe, case i usisivac su prebaceni u ostavu riviere broj 081, u dve braon kutije i jedne kutije od bojlera'), '2026-09-23 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'cc02af11-5188-54c3-8a77-57911d5440be', '2e42fd7e-21e3-56d5-ad1c-4a3b7b76147b', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Crkla masina za sudove, pozvan je ovlasceni servis Bosh i dolaze danas u 12 da poprave, takodje ostavljena i sipka za ormar koju bi danas trebali da namontiraju'), '2026-09-29 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'b7df016a-c717-5f17-931d-51eeff5f22af', '500755dd-4e28-51cd-afed-2085781fd68f', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placen prvi deo depozita 5.000 eura (Sonuç: Predato Jovani)'), '2026-07-30 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'ef7efb35-bfa4-543a-977d-f78cdf6490cb', '500755dd-4e28-51cd-afed-2085781fd68f', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za septembar 5.000 eur'), '2026-08-27 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'dc44d22b-1cd3-5670-88c6-ebfd639091b5', '500755dd-4e28-51cd-afed-2085781fd68f', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za oktobar 5.000 eur'), '2026-10-02 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '15b6880e-c2a2-538e-b071-221c77a0fb9e', '458a1035-8b78-53b8-9313-768d6c5a672a', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Useljen stanar u 1004 i predati kljucevi'), '2026-08-06 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '26ab62dc-5c8e-516c-ab6d-b65e741a412d', '85f588d5-a1c2-566a-b756-c4ce698dbca6', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Pokupljen depozit u iznosu od 5.750 eur kao i renta za period od 15.08.-31.08. u iznosu od 2.470 eur'), '2026-08-10 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '594c891e-2b57-5068-a9d0-90b157726644', '85f588d5-a1c2-566a-b756-c4ce698dbca6', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta u iznosu od 4.460 eur, odbijeno je 40 eur od pune cene rente jer su platili ciscenje'), '2026-09-08 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'c8844634-e920-5aad-bc36-6aba96aa4b47', '85f588d5-a1c2-566a-b756-c4ce698dbca6', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za oktobar u iznosu od 4.500 eur'), '2026-10-07 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'f46c573a-9764-56e2-8f00-6be087faf416', 'b34a30ae-b228-5be0-9b59-21d8980ac274', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'U utorak 04.08. preuzet depozit u iznosu od 1.000 eur, i  predat danas Jovani'), '2026-08-05 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '49cba7a8-65df-506c-b6a2-38245b208f7a', 'b34a30ae-b228-5be0-9b59-21d8980ac274', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Preuzet ostatak depozita u iznosu od 7.600 eura kao i renta za period od 10.08.-31.08. u iznosu od 3.060 eur (Sonuç: dao 10.700 eur, ostaje pretplata 40 eur)'), '2026-08-10 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '144181d9-a59c-58fa-8d13-688c58217b10', 'b34a30ae-b228-5be0-9b59-21d8980ac274', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta u iznosu od 4.260 eur, imali pretplatu 40 eur od proslog meseca'), '2026-09-08 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'a1b3ce8e-163f-56d4-9439-89f48c79f2e9', 'b34a30ae-b228-5be0-9b59-21d8980ac274', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za oktobar 4.300 eur'), '2026-10-02 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '3174305d-1dc2-56cf-8fab-9559d6d3f923', '21a7b98f-23fe-5371-9895-7dfbcfd3e050', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Potpisan ugovor sa novim zakupcem, placen depozit u iznosu od 8.600 i prva renta u iznosu od 4.450 eur (Sonuç: Predato Jovani)'), '2026-08-04 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '6cc23ae9-f383-5cdf-aadf-23b3a0e49ec0', '21a7b98f-23fe-5371-9895-7dfbcfd3e050', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za septembar u iznosu od 4.000 eur, odbijena mu je razlika za prvih 5 dana u avgustu i ostao je duzan 20 eur'), '2026-09-09 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '78feb6f8-896d-5a96-ac03-1f63411d52fd', '21a7b98f-23fe-5371-9895-7dfbcfd3e050', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za oktobar 4.450 eur, plus 20 eur dug od proslog meseca (Sonuç: Dao 4.500 eur, ostaje pretplata 30 eur)'), '2026-10-02 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'f93cedaf-9e7b-5eb6-b622-f94a2a00daaa', '21a7b98f-23fe-5371-9895-7dfbcfd3e050', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Uzet kljuc i dva taga iz kancelarije i data Ivanu, jedan je kljuc ostao na recepciji tako da mu i taj dajem'), '2026-10-16 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'ccb5fb82-1332-554a-9ecf-e085bdca7ec9', 'e87ef13e-8e35-52b6-a84f-2acdf2dd72aa', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Preuzet prvi deo depozita u iznosu od 4.500 eur (Sonuç: Predato Jovani)'), '2026-08-07 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '75b29c65-e1b8-5b64-87e6-e5f31019e2ac', 'e87ef13e-8e35-52b6-a84f-2acdf2dd72aa', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Preuzet drugi deo depozita u iznosu od 4.500 eur'), '2026-08-27 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'd17327b5-1f68-5bd2-a235-efe68f86c40f', 'e87ef13e-8e35-52b6-a84f-2acdf2dd72aa', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za septembar 4.500 eur'), '2026-09-08 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'dac9bef2-e4cb-5a91-8062-771242f8c249', 'e87ef13e-8e35-52b6-a84f-2acdf2dd72aa', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za oktobar 4.500 eur'), '2026-10-02 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '71967c31-2e82-5cb9-b9f4-b48b30ec2cf9', '12810dde-341d-5567-ad7b-7a4d060fe71f', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Pokupljena renta u iznosu od 4.350 eur, Jovani dato za period od 14.08. - 31.08., ostatak ostavljen kod nas da prebacimo za sledeci mesec i da doplati koliko bude trebalo (Sonuç: Dat i depozit u iznosu od 6.525 eur)'), '2026-08-14 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        'b33ca729-5134-5a63-beac-2f7d6558ab39', '12810dde-341d-5567-ad7b-7a4d060fe71f', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za septembar (Sonuç: Dodat iznos od 2.550 eur)'), '2026-09-10 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '5142ffff-7301-5971-863f-e08dd0aa2478', 'd21a40f8-ebd6-5314-b063-f69e818c54d2', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Useljeni novi stanari, placena renta 4.200 eur kao i depozit u iznosu od 8.400 eur'), '2026-10-01 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '28aaacb5-106b-5d32-a685-9e4b0e8af870', 'd1945411-5842-52e2-9988-87b3cb9fa0fd', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Potpisan ugovor o zakupu, placen depozit u iznosu od 3.150 eur kao i prva renta u iznosu od 2.100 eur'), '2026-09-15 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '3b0f4aae-585b-5d7c-a404-6fac116264d3', '2958095f-a25c-58aa-ab38-476cb0f954eb', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena prva renta u iznosu od 1150 eur za period 16.09.-30.09 i depozit u iznosu od 4.600 eur'), '2026-09-16 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;

    INSERT INTO public.activity_logs (
        id, property_id, user_id, type, metadata, created_at
    ) VALUES (
        '6cb9011c-b3fd-510f-b072-31861b0b2582', '2958095f-a25c-58aa-ab38-476cb0f954eb', 'e4a8d708-acf2-4816-b59a-677c7656ce7c', 'manual_note',
        jsonb_build_object('note', 'Placena renta za oktobar u iznosu od 2.300 eur'), '2026-10-01 12:00:00+00'::timestamptz
    ) ON CONFLICT (id) DO UPDATE SET
        metadata = EXCLUDED.metadata,
        created_at = EXCLUDED.created_at;


    -- ------------------------------------------------------------------------------
    -- 3. RENT & BILL PAYMENTS
    -- ------------------------------------------------------------------------------
    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '172b7fff-b12e-5d43-ac97-0aaf4438ffb5', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Kira', 2500.0, 'EUR', '2026-01-01', '2026-01-20',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'fb961dcb-2ef4-5f9e-95e2-9be4ca9ec6d8', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Kira', 2500.0, 'EUR', '2026-02-01', '2026-02-20',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '796187cf-beaf-5f74-9378-cc268ce65ad4', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Kira', 2500.0, 'EUR', '2026-03-01', '2026-03-20',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '9a61955e-cd29-5106-bc74-404cdd53f5b1', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Kira', 2500.0, 'EUR', '2026-04-01', '2026-04-21',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'db24e025-174b-56a4-9023-f8c52a49176d', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Kira', 2500.0, 'EUR', '2026-05-01', '2026-05-20',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '7319ac86-bb8e-5658-9c24-873ee9eca399', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Kira', 2500.0, 'EUR', '2026-06-01', '2026-06-17',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '40e301a6-a4e4-5934-a08e-3ceb98b50e0a', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Kira', 2500.0, 'EUR', '2026-07-01', '2026-07-20',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'ae69effd-38cb-568c-8a3b-3aea8759e0aa', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Kira', 2500.0, 'EUR', '2026-08-01', '2026-08-20',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'd87713d3-d98a-51ec-b17e-0cb4eb0da312', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Kira', 2500.0, 'EUR', '2026-09-01', '2026-09-17',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '01957c61-066e-5eeb-825f-973859287032', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Building Maintenance', 34026.84, 'RSD', '2026-01-15', '2026-02-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'bb78957c-52c1-5798-b9c4-982ad4dd2a78', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Electricity', 20245.73, 'RSD', '2026-01-15', '2026-02-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '5f828685-fb11-514c-a685-cde34d102b00', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Infostan', 26932.2, 'RSD', '2026-01-15', '2026-02-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '3ac3f05d-d64b-5391-b643-9217e3c041d7', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Parking', 1267.55, 'RSD', '2026-01-15', '2026-02-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '2098dee7-5fa5-5c74-83b7-5b619fdd574b', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Building Maintenance', 32560.81, 'RSD', '2026-02-15', '2026-03-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '6a533fd7-7cb0-503d-9e2e-60ea695234fa', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Electricity', 13983.94, 'RSD', '2026-02-15', '2026-03-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '71d95b99-ed15-5604-bc75-78184d4b17cf', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Infostan', 28738.86, 'RSD', '2026-02-15', '2026-03-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'b164936c-156e-5bb8-b2ad-fb983c8f6ee2', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Parking', 1238.66, 'RSD', '2026-02-15', '2026-03-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '4cea34e0-8f13-5844-87e4-198c99f9d6be', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Building Maintenance', 32571.36, 'RSD', '2026-03-15', '2026-04-21',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'e82c5d79-d916-5e45-bafe-b9706a5fb4b9', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Electricity', 11093.85, 'RSD', '2026-03-15', '2026-04-21',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '59a3c56b-0bf6-561f-8ede-b963aad3e7ac', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Infostan', 25772.72, 'RSD', '2026-03-15', '2026-04-21',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '0716a2b8-8eb9-51c1-bfe1-85096d3230f5', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Parking', 1376.98, 'RSD', '2026-03-15', '2026-04-21',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '26182642-74d9-5ad3-b9a5-6f20b61aab38', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Building Maintenance', 32564.8, 'RSD', '2026-04-15', '2026-05-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '5fcdc2fd-6c27-5639-90f9-7e31ff7d86c3', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Electricity', 11476.77, 'RSD', '2026-04-15', '2026-05-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'bf47fb9a-1cad-5956-b8ae-94c06a3272bd', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Infostan', 23548.03, 'RSD', '2026-04-15', '2026-05-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '5dcccdd8-525f-59af-af65-4aa0671f9f45', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Parking', 1241.68, 'RSD', '2026-04-15', '2026-05-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'ce02997d-cfc9-575e-8005-032bd09974bc', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Building Maintenance', 32566.07, 'RSD', '2026-05-15', '2026-06-17',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '3bb25e4e-9d87-595e-a1a0-0bb282df56d2', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Electricity', 11242.3, 'RSD', '2026-05-15', '2026-06-17',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '23ca2795-af94-59c6-a9fe-3d6b5635e067', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Infostan', 21049.36, 'RSD', '2026-05-15', '2026-06-17',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '610c5adc-17d5-5f2b-9f1c-a6b01bf313d1', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Parking', 1287.26, 'RSD', '2026-05-15', '2026-06-17',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'bee75056-a40e-54e4-a11e-4fa8681ed977', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Building Maintenance', 32554.2, 'RSD', '2026-06-15', '2026-07-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '9901c9f9-8bd0-5453-8b4a-8fc03fc309fd', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Electricity', 13742.15, 'RSD', '2026-06-15', '2026-07-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '058fb903-98d0-5517-8918-e0e61e64bbef', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Infostan', 15551.82, 'RSD', '2026-06-15', '2026-07-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'f68f8702-cd6c-57ef-8380-bf491bc5d831', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Parking', 1281.55, 'RSD', '2026-06-15', '2026-07-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'e8dbb6ea-61b9-5df0-b36f-22615089729f', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Building Maintenance', 32563.43, 'RSD', '2026-07-15', '2026-08-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'e1e7c28d-41fa-5f7d-b862-17ed6c4eaa42', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Electricity', 12839.69, 'RSD', '2026-07-15', '2026-08-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '9d640dae-527b-5813-98bc-9a6cc801f0fc', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Infostan', 17302.82, 'RSD', '2026-07-15', '2026-08-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd55dcdf4-9506-582c-90ff-a8eed4b9dd78', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Parking', 1516.4, 'RSD', '2026-07-15', '2026-08-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'c201671f-7b6b-5de7-b3c2-19c3ef496bcf', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Building Maintenance', 32547.61, 'RSD', '2026-08-15', '2026-09-17',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'b2a6b5cc-d52a-5467-a2ad-e40e33e339c8', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Electricity', 16532.08, 'RSD', '2026-08-15', '2026-09-17',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '932de876-4385-56ce-81f9-77e04936ea41', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Infostan', 15346.13, 'RSD', '2026-08-15', '2026-09-17',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '3f469ba6-b6ed-5812-9767-10931939b16d', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Parking', 1232.66, 'RSD', '2026-08-15', '2026-09-17',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'bafb2cae-36ef-50ac-af22-a0e6dbcb496d', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Building Maintenance', 32599.11, 'RSD', '2026-09-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'aae4d08a-086d-5985-821e-c4a9c05a453f', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Electricity', 10498.86, 'RSD', '2026-09-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '552b4c11-47d6-5fbb-af96-4c38e0030427', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Infostan', 19176.29, 'RSD', '2026-09-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'a1630820-c400-5e79-b408-0e672653e237', '054fc448-a11b-54fc-9f66-f6e913fe84d4', '6e6fa932-72d2-5516-9efd-2b77f51f6070', 'Parking', 1117.49, 'RSD', '2026-09-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '45897a36-4394-5144-8622-16aad00f423e', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Kira', 2500.0, 'EUR', '2026-01-01', '2025-01-08',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '4e4e6bec-84fa-52ea-a6f5-4d78696c04e6', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Kira', 2500.0, 'EUR', '2026-02-01', '2026-02-06',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '3028d024-5eb3-5105-a96d-60f2f024ff01', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Kira', 2500.0, 'EUR', '2026-03-01', '2026-03-10',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '1c5b0266-024d-5144-9f3f-cc8bff4b6741', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Kira', 2500.0, 'EUR', '2026-04-01', '2026-04-06',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'c8dceaf0-253a-5419-894f-11303d57ed5b', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Kira', 2500.0, 'EUR', '2026-05-01', '2026-05-06',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'd7f6df25-9249-5234-83e8-fd82741c5989', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Kira', 2500.0, 'EUR', '2026-06-01', '2026-06-09',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '2c43f53b-d409-5c03-b173-b8f60a8baf03', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Kira', 2500.0, 'EUR', '2026-07-01', '2026-07-09',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'fb4ed495-5997-5877-bc61-9ab476764a65', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Kira', 2500.0, 'EUR', '2026-08-01', '2026-08-05',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'c0a956da-f889-545b-945b-1c42721297c1', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Kira', 2500.0, 'EUR', '2026-09-01', '2026-09-08',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'edc463fc-9bc9-5559-9776-e7b578287fd1', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Kira', 2500.0, 'EUR', '2026-10-01', '2026-10-13',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '0a893021-14af-5d9f-906e-8fa58ec2e208', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Building Maintenance', 34029.94, 'RSD', '2026-01-15', '2026-03-10',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '6ec2a998-f992-5176-901c-cd81714ebc1f', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Electricity', 234.55, 'RSD', '2026-01-15', '2026-03-10',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '16c952ad-37e9-5d67-b0d3-6ba6936a65a2', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Infostan', 26136.21, 'RSD', '2026-01-15', '2026-03-10',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '4981bd7b-07cd-5a3d-b7e0-6d3edee020d0', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Parking', 1267.55, 'RSD', '2026-01-15', '2026-03-10',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '7e2774fe-a298-5444-ad0b-efc056327018', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Building Maintenance', 32563.78, 'RSD', '2026-02-15', '2026-04-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'b3284c5d-eb10-5fc9-9574-32f94c0ba83a', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Electricity', 8805.3, 'RSD', '2026-02-15', '2026-04-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'e2455e99-0335-5b89-91f2-d65c5053bad1', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Infostan', 28339.87, 'RSD', '2026-02-15', '2026-04-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'cd6221b4-5170-5520-bbc2-1b8c65b0b424', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Parking', 1251.55, 'RSD', '2026-02-15', '2026-04-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'f31deffd-6ecc-58db-9d88-c6f810f465f8', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Building Maintenance', 32574.32, 'RSD', '2026-03-15', '2026-05-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '2f06a8d2-5f9b-59d7-a007-ee6ffc8fe6d3', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Electricity', 26822.8, 'RSD', '2026-03-15', '2026-05-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'cace500b-7a25-5d0f-a967-d0d0adfb0198', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Infostan', 24718.26, 'RSD', '2026-03-15', '2026-05-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '28be9803-0cbe-5174-bc7f-a1d537c48914', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Parking', 1391.36, 'RSD', '2026-03-15', '2026-05-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '637d92be-3fce-5d62-9e6f-ed1e73fc31d1', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Building Maintenance', 32567.75, 'RSD', '2026-04-15', '2026-06-09',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'b5afae27-834f-578e-9835-75130c91b0cf', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Electricity', 7043.01, 'RSD', '2026-04-15', '2026-06-09',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '05ad6502-2914-513b-ba00-e7a4fd6b118b', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Infostan', 22608.96, 'RSD', '2026-04-15', '2026-06-09',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '911eeec5-28af-564c-a47c-3e7b19307496', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Parking', 1241.68, 'RSD', '2026-04-15', '2026-06-09',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'ef488172-0b34-519c-840f-4b56d2b706aa', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Building Maintenance', 32569.02, 'RSD', '2026-05-15', '2026-07-09',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'e65466a9-7dfa-5047-a997-46324e498403', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Electricity', 9568.74, 'RSD', '2026-05-15', '2026-07-09',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '0611eba1-aba2-5d8c-9ee1-588e167be1dc', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Infostan', 20711.61, 'RSD', '2026-05-15', '2026-07-09',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'b4e1e8ff-2ede-5496-a89e-587befc29815', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Parking', 1287.26, 'RSD', '2026-05-15', '2026-07-09',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '9d38b4ea-a857-5a9b-95c1-43edc69d8ec6', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Building Maintenance', 32557.15, 'RSD', '2026-06-15', '2026-08-05',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '2fceda3d-e5fd-5d8c-90c8-fd8f850f1dba', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Electricity', 10537.8, 'RSD', '2026-06-15', '2026-08-05',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'b1087605-08ec-5b62-8206-55cfc74ce512', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Infostan', 16120.03, 'RSD', '2026-06-15', '2026-08-05',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '000bd72f-5aaf-5991-a1fe-39fec4fd10d7', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Parking', 1281.55, 'RSD', '2026-06-15', '2026-08-05',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'f23e17c1-ce1f-56ea-8318-b2d62168ca31', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Building Maintenance', 32566.39, 'RSD', '2026-07-15', '2026-09-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'a536cca8-14aa-5b2a-9f30-cbb3fe3e1917', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Electricity', 13065.28, 'RSD', '2026-07-15', '2026-09-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '76ae37bf-5415-575f-b273-131143a13814', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Infostan', 17946.5, 'RSD', '2026-07-15', '2026-09-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '88eaea7d-3d21-50c7-82e8-900c636b6679', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Parking', 1516.4, 'RSD', '2026-07-15', '2026-09-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '8c5038f7-5754-525c-b665-717be69534ff', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Building Maintenance', 32550.56, 'RSD', '2026-08-15', '2026-10-13',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '22f4c50c-6e9b-5321-93b8-70b076a317ac', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Electricity', 15949.08, 'RSD', '2026-08-15', '2026-10-13',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '484cdbe3-43ef-5195-9e25-0a91fe6edabc', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Infostan', 15901.19, 'RSD', '2026-08-15', '2026-10-13',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '2911f250-bcbf-5ff9-9341-30514b603dd2', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Parking', 1232.66, 'RSD', '2026-08-15', '2026-10-13',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '4b422204-2976-5628-b3f4-be66893d4639', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Building Maintenance', 32602.06, 'RSD', '2026-09-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '556617c9-c75f-5baa-a53c-11c28c83ee9e', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Electricity', 11798.34, 'RSD', '2026-09-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '2d6a41fa-97ec-58cc-80cd-a773daedbf08', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Infostan', 19902.76, 'RSD', '2026-09-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '820c649f-da02-55e0-b85f-0e7315c526aa', '4a1858ac-cd89-5ded-a31b-67561b05923f', '427e672e-51b9-5343-b047-07ffe1aa9d1c', 'Parking', 1117.49, 'RSD', '2026-09-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'd2f2abbb-c1b2-58eb-b58e-fd5b018d5c0d', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Kira', 3600.0, 'EUR', '2026-01-01', '2025-12-29',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '714b3654-84d0-58c5-a313-c110ba6f2559', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Kira', 3200.0, 'EUR', '2026-02-01', '2026-02-23',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '5c407dce-6dbc-5c64-9657-29cb5f693560', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Kira', 3200.0, 'EUR', '2026-03-01', '2026-03-10',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'c2becadf-eb90-5952-8e53-ddccdd5694d4', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Kira', 3200.0, 'EUR', '2026-04-01', '2026-04-09',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '6f95eda3-28ad-522d-b31a-d6d2fec5c061', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Kira', 3200.0, 'EUR', '2026-05-01', '2026-04-25',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'c9bbb2d1-8996-5abb-8700-4881c933ebff', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Kira', 3200.0, 'EUR', '2026-06-01', '2026-06-26',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '6f5b7d67-290d-5e8a-a51c-0984730cd3be', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Kira', 3200.0, 'EUR', '2026-07-01', '2026-06-26',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'e676b751-8ba8-5370-82ff-31cb6161e1fe', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Kira', 3200.0, 'EUR', '2026-08-01', '2026-07-28',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '66333aca-d6aa-58a0-9d09-d9a0236b55bb', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Kira', 3200.0, 'EUR', '2026-09-01', '2026-09-16',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'ea568589-84ae-58bc-9c8f-aadf98548a64', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Kira', 3200.0, 'EUR', '2026-10-01', '2026-10-16',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'a362eb54-8f70-509f-a267-8e28c27306fb', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Building Maintenance', 30549.02, 'RSD', '2026-01-15', '2026-02-23',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'fb3fac4d-83ef-500d-9e94-9226306f1a2f', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Electricity', 30793.63, 'RSD', '2026-01-15', '2026-02-23',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'a666ede8-fe3b-56d7-b976-530a17c27b81', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Infostan', 31429.09, 'RSD', '2026-01-15', '2026-02-23',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'c71fd38c-af8a-502b-a9b9-1647637b56ee', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Parking', 1106.93, 'RSD', '2026-01-15', '2026-02-23',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'a362eb54-8f70-509f-a267-8e28c27306fb', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Building Maintenance', 4486.25, 'RSD', '2026-01-15', '2026-02-23',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '8d934b55-75e8-52db-986a-e4c26092b156', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Building Maintenance', 30545.32, 'RSD', '2026-02-15', '2026-04-25',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'eec37a7a-ab9b-5ea6-a4fe-3e037c28f1db', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Electricity', 15700.54, 'RSD', '2026-02-15', '2026-04-25',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '1a658c0e-8a04-5d69-849c-6ebc3c8b7e9e', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Infostan', 37398.7, 'RSD', '2026-02-15', '2026-04-25',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'c2e44789-7618-5a8d-a212-d67b5cd3012d', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Parking', 1104.68, 'RSD', '2026-02-15', '2026-04-25',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '8d934b55-75e8-52db-986a-e4c26092b156', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Building Maintenance', 4486.25, 'RSD', '2026-02-15', '2026-04-25',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '6bf08d8b-d156-5c61-a47a-1407be2e4558', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Building Maintenance', 30232.76, 'RSD', '2026-03-15', '2026-05-19',
        'paid', 'Oransal kısmi ödeme (30232.76 RSD ödendi)', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'dcd46240-e432-55e0-abe3-3a946844a205', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Building Maintenance (Kalan)', 316.29, 'RSD', '2026-03-15', NULL,
        'pending', 'Kalan borç bakiyesi (316.29 RSD)', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '1179ae3b-f669-56f5-92f3-7b588babc741', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Electricity', 9249.72, 'RSD', '2026-03-15', '2026-05-19',
        'paid', 'Oransal kısmi ödeme (9249.72 RSD ödendi)', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'a33075bf-b936-5c82-936e-6af5e827c1b8', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Electricity (Kalan)', 96.77, 'RSD', '2026-03-15', NULL,
        'pending', 'Kalan borç bakiyesi (96.77 RSD)', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '8bfbe650-183d-5d64-bd50-0c3b0deef528', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Infostan', 31035.33, 'RSD', '2026-03-15', '2026-05-19',
        'paid', 'Oransal kısmi ödeme (31035.33 RSD ödendi)', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'f7b4fbff-2134-57f3-99df-0aa42ed5ff02', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Infostan (Kalan)', 324.69, 'RSD', '2026-03-15', NULL,
        'pending', 'Kalan borç bakiyesi (324.69 RSD)', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '001b63b3-f2af-583d-a989-27573b4ec739', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Parking', 1092.38, 'RSD', '2026-03-15', '2026-05-19',
        'paid', 'Oransal kısmi ödeme (1092.38 RSD ödendi)', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '0c22e912-29a3-555b-8830-3bcd8bf75458', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Parking (Kalan)', 11.43, 'RSD', '2026-03-15', NULL,
        'pending', 'Kalan borç bakiyesi (11.43 RSD)', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '6bf08d8b-d156-5c61-a47a-1407be2e4558', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Building Maintenance', 4439.8, 'RSD', '2026-03-15', '2026-05-19',
        'paid', 'Oransal kısmi ödeme (4439.80 RSD ödendi)', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'dcd46240-e432-55e0-abe3-3a946844a205', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Building Maintenance (Kalan)', 46.45, 'RSD', '2026-03-15', NULL,
        'pending', 'Kalan borç bakiyesi (46.45 RSD)', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'a9b9a088-96bf-52b8-a9a8-8e17506a6dcb', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Building Maintenance', 30541.73, 'RSD', '2026-04-15', '2026-06-26',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '5156b34c-e31b-59c7-adad-e0eb43124fda', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Electricity', 10689.96, 'RSD', '2026-04-15', '2026-06-26',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'f6c4340f-7542-54f5-b40e-5c7b2d546e9c', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Infostan', 28080.4, 'RSD', '2026-04-15', '2026-06-26',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'b32c9c17-4982-52a6-9783-845d528affa9', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Parking', 1048.16, 'RSD', '2026-04-15', '2026-06-26',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'a9b9a088-96bf-52b8-a9a8-8e17506a6dcb', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Building Maintenance', 4486.25, 'RSD', '2026-04-15', '2026-06-26',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '0e1852d0-f04c-5435-ac62-d3f3fa8261bd', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Building Maintenance', 30549.0, 'RSD', '2026-05-15', '2026-06-26',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '1c950f79-65bf-59fd-b892-16e6d83648a6', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Electricity', 11222.12, 'RSD', '2026-05-15', '2026-06-26',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '57630354-4516-5e22-9127-9597b897fc4f', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Infostan', 26498.67, 'RSD', '2026-05-15', '2026-06-26',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '7a4ad028-c292-549e-9641-cd8d8755ea1a', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Parking', 1110.75, 'RSD', '2026-05-15', '2026-06-26',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '0e1852d0-f04c-5435-ac62-d3f3fa8261bd', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Building Maintenance', 4486.25, 'RSD', '2026-05-15', '2026-06-26',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '95dfddef-e426-5a58-aadd-8c7b89c6aa23', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Building Maintenance', 30534.41, 'RSD', '2026-06-15', '2026-07-28',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '1ecdf07b-d85a-5f3c-865a-d8b300e46b1f', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Electricity', 12715.97, 'RSD', '2026-06-15', '2026-07-28',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd4e1efb9-0026-5c6c-aa0d-7dc80f156ad2', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Infostan', 21198.62, 'RSD', '2026-06-15', '2026-07-28',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'caec41c0-5ca5-55fc-951b-2a18faecb5da', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Parking', 1101.94, 'RSD', '2026-06-15', '2026-07-28',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '95dfddef-e426-5a58-aadd-8c7b89c6aa23', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Building Maintenance', 4486.25, 'RSD', '2026-06-15', '2026-07-28',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '15bfd1a8-d562-5160-b616-a6d4d7f66d84', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Building Maintenance', 30543.51, 'RSD', '2026-07-15', '2026-09-16',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '03b704f1-79d1-59fc-9c28-c85d6a8c1134', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Electricity', 13833.66, 'RSD', '2026-07-15', '2026-09-16',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '4f99adc9-149b-5db6-b74e-89ed7c7fe56c', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Infostan', 16719.16, 'RSD', '2026-07-15', '2026-09-16',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'fdb63511-5130-5e15-9e1c-8ec69d33bc7d', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Parking', 1109.68, 'RSD', '2026-07-15', '2026-09-16',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '15bfd1a8-d562-5160-b616-a6d4d7f66d84', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Building Maintenance', 4486.25, 'RSD', '2026-07-15', '2026-09-16',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd9ee7eb7-546d-5140-8f8d-8e85b6851a6b', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Building Maintenance', 30530.72, 'RSD', '2026-08-15', '2026-10-16',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '5ed79f9e-619d-5e62-8ae2-a08f2f4b101d', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Electricity', 14023.45, 'RSD', '2026-08-15', '2026-10-16',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '599a2bde-4a19-5d2e-ab60-7e3ad08bf01e', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Infostan', 18942.09, 'RSD', '2026-08-15', '2026-10-16',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'a55a4f74-1b2a-50b2-b01e-15f6d36caf11', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Parking', 1061.56, 'RSD', '2026-08-15', '2026-10-16',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd9ee7eb7-546d-5140-8f8d-8e85b6851a6b', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Building Maintenance', 4486.25, 'RSD', '2026-08-15', '2026-10-16',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '56f98003-cf3c-5364-9604-8b31aecdd5b5', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Building Maintenance', 30571.18, 'RSD', '2026-09-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'c8bd6402-c288-5dce-8ba1-6a83b1513cc8', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Infostan', 26101.05, 'RSD', '2026-09-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '87123c02-48b4-5201-83d5-e4777efc1d17', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Parking', 1129.08, 'RSD', '2026-09-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '56f98003-cf3c-5364-9604-8b31aecdd5b5', 'e61bb149-92ce-573d-bc56-ee127e6e45a7', 'a71aaf01-64a9-5078-9f2b-49de6d570795', 'Building Maintenance', 4486.25, 'RSD', '2026-09-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'cee28c16-ea46-57e8-9285-6f6524d1674e', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Kira', 3000.0, 'EUR', '2026-01-01', NULL,
        'paid', 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '5cf2db7b-3897-552f-aa5f-539b2e085d7e', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Kira', 3000.0, 'EUR', '2026-02-01', NULL,
        'paid', 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '52c1c57d-d821-5de7-afe2-7c3e49bd7ec1', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Kira', 3000.0, 'EUR', '2026-03-01', '2026-03-26',
        'paid', 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'b331b1ef-ff52-5e89-80f6-d248a710fe42', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Kira', 3000.0, 'EUR', '2026-04-01', '2026-04-16',
        'paid', 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'f434114c-742f-540d-b305-f2f6942b37a3', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Kira', 3000.0, 'EUR', '2026-05-01', '2026-05-13',
        'paid', 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'e178e08a-6a79-5502-ba2a-db6362284014', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Kira', 3000.0, 'EUR', '2026-06-01', '2026-06-22',
        'paid', 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '4642c965-7eb8-585a-9bdf-d56ec30aacfa', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Kira', 3000.0, 'EUR', '2026-07-01', '2026-08-04',
        'paid', 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'ee0bb615-2f04-5679-ab06-4cbb1b16b863', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Kira', 3000.0, 'EUR', '2026-08-01', '2026-08-24',
        'paid', 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '987c8c55-7b65-526b-afe3-c9d2ddb5864c', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Building Maintenance', 34416.63, 'RSD', '2026-01-15', '2026-04-22',
        'paid', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '9274ab21-4f77-5f6e-8062-4f4c992e0040', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Infostan', 29445.71, 'RSD', '2026-01-15', '2026-04-22',
        'paid', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '3057e128-d62b-500c-9ec4-8354a81005d5', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Parking', 655.94, 'RSD', '2026-01-15', '2026-04-22',
        'paid', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '987c8c55-7b65-526b-afe3-c9d2ddb5864c', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Building Maintenance', 4831.39, 'RSD', '2026-01-15', '2026-04-22',
        'paid', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '0c405676-0275-54cb-962a-a462945f0b34', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Building Maintenance', 34411.5, 'RSD', '2026-02-15', '2026-04-22',
        'paid', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '62e96b34-5d77-5071-a916-1f21dc7d0c4a', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Electricity', 88371.78, 'RSD', '2026-02-15', '2026-04-22',
        'paid', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '65f827a1-8f33-5d11-adbe-c19cc9ac6b2a', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Infostan', 35941.58, 'RSD', '2026-02-15', '2026-04-22',
        'paid', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'c275606d-6b6f-5c61-ab35-72edc9bc698d', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Parking', 683.73, 'RSD', '2026-02-15', '2026-04-22',
        'paid', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '0c405676-0275-54cb-962a-a462945f0b34', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Building Maintenance', 4831.31, 'RSD', '2026-02-15', '2026-04-22',
        'paid', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '2826433d-0a51-5ece-b127-a085634fbae7', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Building Maintenance', 34417.71, 'RSD', '2026-03-15', '2026-09-03',
        'paid', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '8f064136-de2f-5feb-ae2a-3fd185875057', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Electricity', 4552.37, 'RSD', '2026-03-15', '2026-09-03',
        'paid', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'ef146cd0-3130-5969-b411-18e28b6b137c', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Infostan', 27380.17, 'RSD', '2026-03-15', '2026-09-03',
        'paid', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '3089b1e9-2f04-5272-a783-539302676d6b', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Parking', 703.52, 'RSD', '2026-03-15', '2026-09-03',
        'paid', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '2826433d-0a51-5ece-b127-a085634fbae7', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Building Maintenance', 4831.4, 'RSD', '2026-03-15', '2026-09-03',
        'paid', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '66f04677-7d54-55e2-8ed0-ca918f8d9d66', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Building Maintenance', 34409.7, 'RSD', '2026-04-15', '2026-09-03',
        'paid', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd952e738-1e7c-59ff-bf09-841e721eb7ce', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Electricity', 4189.12, 'RSD', '2026-04-15', '2026-09-03',
        'paid', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'f7f72d29-abbb-5348-860b-0bd94de30807', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Infostan', 21711.55, 'RSD', '2026-04-15', '2026-09-03',
        'paid', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'eb66e451-ae8f-5042-8652-a611016881ee', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Parking', 643.36, 'RSD', '2026-04-15', '2026-09-03',
        'paid', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '66f04677-7d54-55e2-8ed0-ca918f8d9d66', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Building Maintenance', 4831.28, 'RSD', '2026-04-15', '2026-09-03',
        'paid', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '9112cbed-0852-5ad5-96c0-b64a68d22fab', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Building Maintenance', 29532.85, 'RSD', '2026-05-15', '2026-09-03',
        'paid', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'b0062262-e312-5aae-80bd-ab761df801b0', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Electricity', 4830.94, 'RSD', '2026-05-15', '2026-09-03',
        'paid', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'a1712bab-e49f-55a7-813c-c2d72e550cc1', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Infostan', 19607.55, 'RSD', '2026-05-15', '2026-09-03',
        'paid', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'c3f6bce2-d734-5ea2-8d64-5ca8ffb11809', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Parking', 651.4, 'RSD', '2026-05-15', '2026-09-03',
        'paid', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '9112cbed-0852-5ad5-96c0-b64a68d22fab', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Building Maintenance', 4831.38, 'RSD', '2026-05-15', '2026-09-03',
        'paid', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'c2366d5d-8412-58bd-b3a8-fc379d7b2767', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Building Maintenance', 29520.83, 'RSD', '2026-06-15', NULL,
        'pending', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '47f9c491-10c3-5775-954a-b756c6ccd70e', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Electricity', 10451.91, 'RSD', '2026-06-15', NULL,
        'pending', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '7feea418-8ddc-5d4e-9ccf-1754802dcdde', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Infostan', 13247.35, 'RSD', '2026-06-15', NULL,
        'pending', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '9beb3f89-52d4-5b7d-b606-2c3b0fb49faf', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Parking', 671.69, 'RSD', '2026-06-15', NULL,
        'pending', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'c2366d5d-8412-58bd-b3a8-fc379d7b2767', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Building Maintenance', 4831.16, 'RSD', '2026-06-15', NULL,
        'pending', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '13234556-9c89-5f9e-93c7-f98acc963299', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Building Maintenance', 29527.51, 'RSD', '2026-07-15', NULL,
        'pending', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '1510df9d-b19a-5118-bf4f-16682f750bda', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Electricity', 11741.24, 'RSD', '2026-07-15', NULL,
        'pending', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd0d9be99-911d-5a12-832e-6280e4754efc', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Infostan', 13047.12, 'RSD', '2026-07-15', NULL,
        'pending', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'b84a9965-63b8-5103-89d4-30d37e27cf13', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Parking', 694.64, 'RSD', '2026-07-15', NULL,
        'pending', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '13234556-9c89-5f9e-93c7-f98acc963299', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Building Maintenance', 1056.56, 'RSD', '2026-07-15', NULL,
        'pending', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '13234556-9c89-5f9e-93c7-f98acc963299', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Building Maintenance', 13942.87, 'RSD', '2026-07-15', NULL,
        'pending', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '75fe706a-0041-5a28-b874-fd596ffb0bb9', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Building Maintenance', 29516.65, 'RSD', '2026-08-15', NULL,
        'pending', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '18819de3-e367-5e5f-8cab-a19a2b6f2877', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Electricity', 17676.27, 'RSD', '2026-08-15', NULL,
        'pending', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'a8d65630-aab8-536d-920a-35873cd84b18', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Infostan', 13255.37, 'RSD', '2026-08-15', NULL,
        'pending', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'fbdb6934-2dfc-5d17-9b9e-51487c43ed80', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Parking', 688.83, 'RSD', '2026-08-15', NULL,
        'pending', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '75fe706a-0041-5a28-b874-fd596ffb0bb9', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Building Maintenance', 1056.18, 'RSD', '2026-08-15', NULL,
        'pending', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '75fe706a-0041-5a28-b874-fd596ffb0bb9', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Building Maintenance', 4831.09, 'RSD', '2026-08-15', NULL,
        'pending', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'ea2f641e-6cac-5cdd-a194-3c10341fe853', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Building Maintenance', 29557.8, 'RSD', '2026-09-15', NULL,
        'pending', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'faa99c5b-59ed-54e1-acee-0de45e7d2418', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Electricity', 9422.66, 'RSD', '2026-09-15', NULL,
        'pending', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '14b6d710-afe0-51d8-b30d-574c0f4def3d', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Infostan', 18147.12, 'RSD', '2026-09-15', NULL,
        'pending', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '04b8487f-831d-5d6d-b037-3c2669d5fa67', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Parking', 761.77, 'RSD', '2026-09-15', NULL,
        'pending', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'ea2f641e-6cac-5cdd-a194-3c10341fe853', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Building Maintenance', 1057.66, 'RSD', '2026-09-15', NULL,
        'pending', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'ea2f641e-6cac-5cdd-a194-3c10341fe853', '2b57ad41-50e0-578e-a0c8-c281e7391e3a', '3494ba18-d5ca-5ff6-a910-ffa21fded42a', 'Building Maintenance', 14089.79, 'RSD', '2026-09-15', NULL,
        'pending', NULL, 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'e4803c63-4cd0-5c91-944a-a10340ecc3c9', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Kira', 1800.0, 'EUR', '2026-01-01', '2026-01-13',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '6de11376-544e-5f7e-ac64-9565ba88619c', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Kira', 1800.0, 'EUR', '2026-02-01', '2026-02-12',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '09d84072-f26e-58ef-b867-74d47cb5d4aa', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Kira', 1800.0, 'EUR', '2026-03-01', '2026-03-19',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '557ed46d-126d-551c-978b-27d083a55fbe', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Kira', 1800.0, 'EUR', '2026-04-01', '2026-04-06',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '27521eef-3fb0-5f91-a842-cdee02d1285c', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Kira', 1800.0, 'EUR', '2026-05-01', '2026-05-08',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '4577fbc4-6287-5cc5-abd4-decbcd21bf6a', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Kira', 1800.0, 'EUR', '2026-06-01', '2026-06-03',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'a575b275-9bf7-53da-afa3-b16856f8dec4', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Kira', 1800.0, 'EUR', '2026-07-01', '2026-07-01',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '1ae2daa1-0987-5709-bd80-8549b92150d6', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Kira', 1800.0, 'EUR', '2026-08-01', '2026-07-31',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'faa9e889-0e1c-5339-af5b-ff238aa5093b', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Kira', 1800.0, 'EUR', '2026-09-01', '2026-09-01',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'f345715e-3cb1-54dc-99bd-1d060dec4998', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Kira', 1800.0, 'EUR', '2026-10-01', '2026-10-01',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '02491574-8744-50d8-857d-b16f727069e8', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Building Maintenance', 21601.82, 'RSD', '2026-01-15', '2026-03-19',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '87492e2a-9270-50fe-b56c-e5a329e52f29', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Electricity', 1911.31, 'RSD', '2026-01-15', '2026-03-19',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '93ca0366-88e4-561a-8698-83801d035761', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Infostan', 13704.45, 'RSD', '2026-01-15', '2026-03-19',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '596e4992-ccc0-522b-8e02-7c53e14711e0', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Parking', 700.04, 'RSD', '2026-01-15', '2026-03-19',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'b5723bb8-0b29-5d02-8a78-c1ce6297c4e5', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Building Maintenance', 20744.37, 'RSD', '2026-02-15', '2026-04-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '698f5efe-5beb-5184-a06b-81a752c6c47d', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Electricity', 1911.32, 'RSD', '2026-02-15', '2026-04-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '274b4ca1-c611-5253-8119-2b5717b1bef8', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Infostan', 15501.76, 'RSD', '2026-02-15', '2026-04-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '5ad287e7-edd7-5efd-b788-48552b3b2421', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Parking', 691.85, 'RSD', '2026-02-15', '2026-04-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'c4fc8995-c3a0-56ba-aba2-7e29799f4e4f', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Building Maintenance', 20750.76, 'RSD', '2026-03-15', '2026-05-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'bff5497d-251e-578a-83c6-67a2f20dae38', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Electricity', 1911.32, 'RSD', '2026-03-15', '2026-05-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'a3b891af-33ab-5071-a80d-3803cc94820d', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Infostan', 13375.87, 'RSD', '2026-03-15', '2026-05-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '81930f0e-1db3-5e9b-8429-bae7c523d2ff', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Parking', 650.12, 'RSD', '2026-03-15', '2026-05-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '239553a3-d749-5ea5-a70f-d6cb932b8c8b', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Building Maintenance', 20746.79, 'RSD', '2026-04-15', '2026-06-03',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '03637ce4-2a6c-54e8-aeef-3a41996c9260', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Electricity', 1911.32, 'RSD', '2026-04-15', '2026-06-03',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd0815564-7171-5d6a-bf93-f9c23b39b66f', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Infostan', 11929.9, 'RSD', '2026-04-15', '2026-06-03',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '3283b514-9931-5775-959b-95188a6560bf', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Parking', 621.33, 'RSD', '2026-04-15', '2026-06-03',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '7a88d5b5-9383-52fc-bae3-77ae3cdde357', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Building Maintenance', 20746.81, 'RSD', '2026-05-15', '2026-07-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '7e8f605c-8967-576f-80b7-b7e582f381ac', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Electricity', 1911.32, 'RSD', '2026-05-15', '2026-07-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '2b442478-0d99-5713-8e9c-1d3bd7274bd9', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Infostan', 11536.67, 'RSD', '2026-05-15', '2026-07-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '1fed7546-6f7d-5ad6-94ef-f7e85486e7d5', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Parking', 652.73, 'RSD', '2026-05-15', '2026-07-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '7bb81705-756c-5912-b667-d6851e0c9396', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Building Maintenance', 20740.34, 'RSD', '2026-06-15', '2026-07-31',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'f02d4c85-1c07-5232-848d-3f5be2d7f7c2', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Electricity', 1911.32, 'RSD', '2026-06-15', '2026-07-31',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '8848f6af-6988-5b06-bc3e-004da8e74918', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Infostan', 9283.39, 'RSD', '2026-06-15', '2026-07-31',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '7c6ef4a5-8809-5bbc-9ad4-7bd1dd16625b', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Parking', 672.72, 'RSD', '2026-06-15', '2026-07-31',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '7202a883-6771-5afc-b6b3-614281c72559', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Building Maintenance', 20745.95, 'RSD', '2026-07-15', '2026-09-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'f7cc82ad-4172-5513-843a-5a136e199ed5', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Electricity', 1911.32, 'RSD', '2026-07-15', '2026-09-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '84a2f417-34fa-59c4-b110-e14889774b28', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Infostan', 8812.41, 'RSD', '2026-07-15', '2026-09-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '2ce8a4d9-b43c-580f-804a-901ee9ef2e36', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Parking', 660.17, 'RSD', '2026-07-15', '2026-09-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'ccfc1b03-e822-5854-931d-53e799322a98', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Building Maintenance', 20735.73, 'RSD', '2026-08-15', '2026-10-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'aed82c46-a9ef-55ca-8c05-a7f4f3c84fa6', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Electricity', 1911.32, 'RSD', '2026-08-15', '2026-10-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'ee0d384b-cd84-59de-b2f0-498e26292c2e', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Infostan', 8801.14, 'RSD', '2026-08-15', '2026-10-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '86eaebc3-adbb-5a61-b573-9a81f4f67654', 'd2cd1c46-4fac-5919-a741-93f34e980743', 'b9c8a574-91f2-5d66-a6cc-b644ca9c443a', 'Parking', 647.33, 'RSD', '2026-08-15', '2026-10-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '5793b1e1-0b30-5a27-b93a-16c9e23ad056', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Kira', 2450.0, 'EUR', '2026-01-01', '2026-01-15',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'bed8941a-005f-5c1d-a092-097e61d4f99d', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Kira', 2450.0, 'EUR', '2026-02-01', '2026-02-04',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '8aae5384-9afd-534d-82cd-6414c4f070b0', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Kira', 2450.0, 'EUR', '2026-03-01', '2026-03-03',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '32ec2090-f175-53d7-902c-68f751f79b63', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Kira', 2450.0, 'EUR', '2026-04-01', '2026-04-01',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'f2a038f3-e04e-5f44-b57c-f6cbf07985c8', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Kira', 2450.0, 'EUR', '2026-05-01', '2026-04-28',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '6a1f7513-68a3-55e5-9ab5-155d62a5a6f9', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Kira', 2450.0, 'EUR', '2026-06-01', '2026-06-02',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '19a0fd85-ba1d-538b-991d-8088e68e9aa5', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Kira', 2450.0, 'EUR', '2026-07-01', '2026-07-01',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '5727eff7-b5b6-5c0a-8b00-d7619a2bfc43', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Kira', 2450.0, 'EUR', '2026-08-01', '2026-08-03',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '7300f76c-f261-5047-b7c5-9bbb1610cce8', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Kira', 2450.0, 'EUR', '2026-09-01', '2026-09-08',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'af338d97-ddee-5940-8d5d-c81c0ca4ca4b', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Kira', 2450.0, 'EUR', '2026-10-01', '2026-10-01',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'b28fa329-cb0b-51f1-a1b2-6f66bfdc9885', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Building Maintenance', 21247.86, 'RSD', '2026-01-15', '2026-03-03',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '67cdaf03-a509-5ab7-9e5a-f8f9c0f0ab55', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Electricity', 19081.76, 'RSD', '2026-01-15', '2026-03-03',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'ea3cf6d8-f055-5b52-90f8-7e97e12d9375', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Infostan', 18523.86, 'RSD', '2026-01-15', '2026-03-03',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd852948f-9f8b-5c02-9ace-7c7ff25eefac', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Parking', 619.89, 'RSD', '2026-01-15', '2026-03-03',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '5c7cf621-2fc8-527e-9272-94f25331784c', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Building Maintenance', 21244.8, 'RSD', '2026-02-15', '2026-04-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '67efbf14-3035-556e-a051-8d7364cea90f', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Electricity', 14965.62, 'RSD', '2026-02-15', '2026-04-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '7fdb6541-4b72-5371-a102-474c21ca6933', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Infostan', 25568.6, 'RSD', '2026-02-15', '2026-04-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'c70f463f-2ef8-5310-bd3d-fa860a134099', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Parking', 684.05, 'RSD', '2026-02-15', '2026-04-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '9d4129a8-82d8-5b8c-b2e3-bf143658b206', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Building Maintenance', 21251.0, 'RSD', '2026-03-15', '2026-04-28',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '84606d8d-6070-55b3-9cf8-ccc908c42c6b', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Electricity', 13904.03, 'RSD', '2026-03-15', '2026-04-28',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'bff461bc-065a-5e3f-9077-81cf3e475d73', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Infostan', 21343.57, 'RSD', '2026-03-15', '2026-04-28',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '599b6f76-eadd-5d46-b179-41a964ba24d3', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Parking', 1159.15, 'RSD', '2026-03-15', '2026-04-28',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd54ea62d-f31b-5785-9cd0-e363c0a36169', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Building Maintenance', 21247.88, 'RSD', '2026-04-15', '2026-06-02',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'dfd79f90-309a-538e-bcf9-fb68fef9ccf4', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Electricity', 13074.71, 'RSD', '2026-04-15', '2026-06-02',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '7c41f7f5-1e61-5b99-acf5-456c12bfcf78', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Infostan', 17380.81, 'RSD', '2026-04-15', '2026-06-02',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'c51f1e08-1c5a-5b49-8ded-8fdd79bc5fb0', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Parking', 1157.34, 'RSD', '2026-04-15', '2026-06-02',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '9c28df62-3bbd-5214-b2c9-86ad8e8cac7b', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Building Maintenance', 21247.89, 'RSD', '2026-05-15', '2026-07-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'c4473d15-803b-5f41-a07e-99c1093f552f', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Electricity', 15864.71, 'RSD', '2026-05-15', '2026-07-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '50fe221e-b85a-5599-b481-be288186d4fe', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Infostan', 16019.89, 'RSD', '2026-05-15', '2026-07-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'ffd252ad-e1de-52ce-98a6-a3b74e71de14', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Parking', 1208.96, 'RSD', '2026-05-15', '2026-07-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '99ed0400-2cca-5a37-b4d0-7f7043008e92', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Building Maintenance', 21240.17, 'RSD', '2026-06-15', '2026-08-03',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'b60db0f3-dd83-5a52-b87f-d8005de4dd42', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Electricity', 16464.52, 'RSD', '2026-06-15', '2026-08-03',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '1046bc4b-508c-591a-810b-8a6bd3eadc2e', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Infostan', 12755.46, 'RSD', '2026-06-15', '2026-08-03',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '83ab17c5-cbbe-52f6-83ea-3d11ef8dfba1', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Parking', 1176.47, 'RSD', '2026-06-15', '2026-08-03',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'a7e8f19b-ecbc-5494-9572-bdd130423aa2', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Building Maintenance', 21246.44, 'RSD', '2026-07-15', '2026-09-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '34098771-4319-51bd-9578-991051679bad', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Electricity', 17761.38, 'RSD', '2026-07-15', '2026-09-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'c673e6bc-c124-5ef8-a441-687dcc9b5e1b', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Infostan', 12457.19, 'RSD', '2026-07-15', '2026-09-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'f44045eb-cb63-51e4-a1ca-016a117dbb26', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Parking', 686.4, 'RSD', '2026-07-15', '2026-09-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '4a96b02b-d780-5681-9444-805da2f247d5', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Building Maintenance', 22682.37, 'RSD', '2026-08-15', '2026-10-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '7aabd8ed-0e36-5773-89ef-1ad2de89508a', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Electricity', 22860.23, 'RSD', '2026-08-15', '2026-10-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '7d3a6946-224d-5b86-b77e-91190ba9fda0', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Infostan', 12581.09, 'RSD', '2026-08-15', '2026-10-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'ffcbadfe-2cb3-5582-add8-2d7cec79cfe1', '3202a566-41ba-594d-8870-f5f37147e9a0', 'ce1cf655-bc33-54e2-901e-3b949608ba6a', 'Parking', 686.81, 'RSD', '2026-08-15', '2026-10-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '9af1b221-e4bb-5f8d-9ea6-06a57e269ee9', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Kira', 2500.0, 'EUR', '2026-01-01', '2026-01-08',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '5ca435ba-8108-5418-a9fb-6087a0dd7469', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Kira', 2500.0, 'EUR', '2026-02-01', '2026-02-04',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '69b3bcdb-ca2f-519b-9cc3-0df441d638ca', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Kira', 2500.0, 'EUR', '2026-03-01', '2026-03-04',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '0597e9bc-ade2-565a-af05-3a2b3f356c05', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Kira', 2500.0, 'EUR', '2026-04-01', '2026-04-06',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'a5beefd0-b2b6-5bb4-8f1a-d1f361d3c7a0', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Kira', 2500.0, 'EUR', '2026-05-01', '2026-05-04',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'fbe83939-da61-5a14-a3c6-da86ebb78740', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Kira', 2500.0, 'EUR', '2026-06-01', '2026-06-03',
        'pending', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '82d5c992-2e2d-5275-b0af-de4467145a9c', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Kira', 2500.0, 'EUR', '2026-07-01', '2026-07-02',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'd910b394-1bbb-5f0e-a701-79ad5408e27d', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Kira', 2500.0, 'EUR', '2026-08-01', '2026-08-06',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '756f200a-118c-5265-bb6f-4041ee82aac3', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Kira', 2500.0, 'EUR', '2026-09-01', '2026-09-01',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '2fd1f627-f7d1-5873-990a-eba0a4871f8b', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Kira', 2500.0, 'EUR', '2026-10-01', '2026-10-02',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'c1f4fa38-bc94-515c-84f3-6e776774114c', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Building Maintenance', 21251.16, 'RSD', '2026-01-15', '2026-02-23',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'e78e4449-9332-56cd-b3b4-f0d7cb813c6e', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Electricity', 10699.68, 'RSD', '2026-01-15', '2026-02-23',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'e156ee8f-b104-5f78-9e2b-e616f546524c', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Infostan', 20943.26, 'RSD', '2026-01-15', '2026-02-23',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '997da405-ad9b-513e-afc4-6da788bfd5cd', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Parking', 619.89, 'RSD', '2026-01-15', '2026-02-23',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '6ad85038-9160-52c7-9723-0ad0cfe5dcbf', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Building Maintenance', 21248.1, 'RSD', '2026-02-15', '2026-03-26',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '5985fe75-6d7a-5d60-b1c7-8d7c7b34f235', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Electricity', 11490.16, 'RSD', '2026-02-15', '2026-03-26',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '8529b217-c4c8-57b1-b3d5-ef744e8a50de', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Infostan', 23466.63, 'RSD', '2026-02-15', '2026-03-26',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '6aa37c65-5921-5b54-9cfc-4e99b1ea3fd0', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Parking', 684.05, 'RSD', '2026-02-15', '2026-03-26',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'de78c90a-2314-5254-b42a-b64806d8b01a', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Building Maintenance', 21254.3, 'RSD', '2026-03-15', '2026-05-04',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '221f2461-3eb4-554d-99c2-84b29961bfef', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Electricity', 12074.48, 'RSD', '2026-03-15', '2026-05-04',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '18624e85-187f-5efa-ab61-bd6f063e7c91', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Infostan', 18812.64, 'RSD', '2026-03-15', '2026-05-04',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'de00545a-6749-5403-9cfd-f8d873e4bcb6', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Parking', 1159.15, 'RSD', '2026-03-15', '2026-05-04',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '84bdbdee-4304-54ed-97bf-04c3f9eb6fa2', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Building Maintenance', 21251.18, 'RSD', '2026-04-15', '2026-06-03',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '850d109a-5b4f-59c8-bad1-210381c86476', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Electricity', 11271.69, 'RSD', '2026-04-15', '2026-06-03',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'dd82b8e5-729a-5659-aa50-d7658a6babba', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Infostan', 15266.96, 'RSD', '2026-04-15', '2026-06-03',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '03cc64e4-8483-54b5-bf1e-2523a9683e35', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Parking', 1207.52, 'RSD', '2026-04-15', '2026-06-03',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '98522c4d-ead3-5178-8bce-82263cc200d5', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Building Maintenance', 21251.19, 'RSD', '2026-05-15', '2026-06-23',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'e048f857-c091-5ace-818d-386ed42ce1c4', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Electricity', 14343.92, 'RSD', '2026-05-15', '2026-06-23',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '2c8c7ebe-34af-5d30-bd3a-211f76d9fb65', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Infostan', 16904.12, 'RSD', '2026-05-15', '2026-06-23',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'a8ebf27e-e787-5692-8415-86e56ff343a3', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Parking', 1219.65, 'RSD', '2026-05-15', '2026-06-23',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '175ddf3f-8a8c-574f-baeb-379e8f98ad72', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Building Maintenance', 21243.45, 'RSD', '2026-06-15', '2026-08-17',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'eabddc73-48f7-5a8d-9884-ebf9ce193530', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Electricity', 18056.87, 'RSD', '2026-06-15', '2026-08-17',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '62de9018-8799-52fb-9cea-1e22329e41b4', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Infostan', 12852.99, 'RSD', '2026-06-15', '2026-08-17',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '8ce28fed-2ca2-58a1-acb5-11ae39385886', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Parking', 1186.81, 'RSD', '2026-06-15', '2026-08-17',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'de210293-7075-598d-b6c3-4d62d11d3c32', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Building Maintenance', 21249.74, 'RSD', '2026-07-15', '2026-08-19',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'f5a5598a-029b-5857-a038-1b30b6187371', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Electricity', 20279.64, 'RSD', '2026-07-15', '2026-08-19',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '139a4453-5e60-5887-b25a-873f181832f8', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Infostan', 12551.56, 'RSD', '2026-07-15', '2026-08-19',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '9de691c5-a90e-5a1e-8196-014090986fa1', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Parking', 691.52, 'RSD', '2026-07-15', '2026-08-19',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '3a7d45d8-6216-5373-b26e-0e5fdbadbca0', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Building Maintenance', 22685.66, 'RSD', '2026-08-15', '2026-10-02',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd89336b6-bc3f-5478-8f5c-2036498c8aab', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Electricity', 27605.44, 'RSD', '2026-08-15', '2026-10-02',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '1222a07c-fe4f-5a5f-8844-981c447a89ad', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Infostan', 13155.23, 'RSD', '2026-08-15', '2026-10-02',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'cd439819-be1d-59ef-a3dd-88226b5d5d59', '258e2700-87eb-50a2-9a3d-5675b2a1954d', 'd7c6aad8-5fb5-5ee3-a50c-a3c6f3c113b1', 'Parking', 717.61, 'RSD', '2026-08-15', '2026-10-02',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '47277fe3-a644-556c-85bc-a10fb379a585', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Kira', 1650.0, 'EUR', '2026-01-01', NULL,
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '85dd0ae8-227f-5d45-b50d-72511a224c4d', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Kira', 1650.0, 'EUR', '2026-02-01', NULL,
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '81578195-432b-5429-a136-98d46fff0f26', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Kira', 1650.0, 'EUR', '2026-03-01', '2026-03-27',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '42cc3eef-2224-5a9e-8778-86fdabe61775', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Kira', 1650.0, 'EUR', '2026-04-01', '2026-04-15',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '8afe30ed-9739-545e-96df-4fb61d92ab0a', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Kira', 1650.0, 'EUR', '2026-05-01', '2026-05-12',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '29a94885-4d74-5e32-bf59-a09a8cf2fc46', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Kira', 1650.0, 'EUR', '2026-06-01', '2026-06-17',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'fc71dd84-49da-5848-ad00-0aa1bfa75bd4', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Kira', 1650.0, 'EUR', '2026-07-01', '2026-07-27',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '05090e33-072c-5c47-a7ae-c9a4112fad66', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Kira', 1650.0, 'EUR', '2026-08-01', '2026-08-04',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '56c9cb12-0bc4-5f8e-92fc-2439e2b7da1a', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Kira', 1650.0, 'EUR', '2026-09-01', '2026-09-07',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '28047c28-05fd-5471-a7de-553c64267995', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Building Maintenance', 19348.55, 'RSD', '2026-01-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '28047c28-05fd-5471-a7de-553c64267995', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Building Maintenance', 2262.02, 'RSD', '2026-01-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '28047c28-05fd-5471-a7de-553c64267995', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Building Maintenance', 7324.78, 'RSD', '2026-01-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '28047c28-05fd-5471-a7de-553c64267995', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Building Maintenance', 2699.0, 'RSD', '2026-01-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '131e0d64-de5e-508b-bde8-42275e2ffef6', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Electricity', 3644.27, 'RSD', '2026-01-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '7f7aa595-874c-5c01-bcf1-39297a802cd5', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Infostan', 6245.66, 'RSD', '2026-01-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'a7c4d0ac-dd54-5e36-9167-845b5275c9da', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Parking', 802.75, 'RSD', '2026-01-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '153b50c2-b328-5319-a998-5383a3f4c467', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Internet/TV', 5400.0, 'RSD', '2026-01-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '64064079-3953-59f8-b77f-8b6b84e14d25', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Building Maintenance', 19346.0, 'RSD', '2026-02-15', '2026-05-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '64064079-3953-59f8-b77f-8b6b84e14d25', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Building Maintenance', 2791.4, 'RSD', '2026-02-15', '2026-05-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '64064079-3953-59f8-b77f-8b6b84e14d25', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Building Maintenance', 10032.63, 'RSD', '2026-02-15', '2026-05-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '64064079-3953-59f8-b77f-8b6b84e14d25', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Building Maintenance', 2699.0, 'RSD', '2026-02-15', '2026-05-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'afbe1a0a-bf43-507d-9cc8-9b7ad071b656', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Electricity', 3318.22, 'RSD', '2026-02-15', '2026-05-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '9933682f-ac67-58b8-9491-152543db7892', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Infostan', 6150.83, 'RSD', '2026-02-15', '2026-05-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '1de4e795-7194-560b-bbb1-a9a52db01e01', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Parking', 4107.04, 'RSD', '2026-02-15', '2026-05-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '2749c819-8c5a-587d-a39e-33193f8f0c7a', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Building Maintenance', 19352.51, 'RSD', '2026-03-15', '2026-06-17',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '2749c819-8c5a-587d-a39e-33193f8f0c7a', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Building Maintenance', 2253.6, 'RSD', '2026-03-15', '2026-06-17',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '2749c819-8c5a-587d-a39e-33193f8f0c7a', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Building Maintenance', 6384.73, 'RSD', '2026-03-15', '2026-06-17',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '2749c819-8c5a-587d-a39e-33193f8f0c7a', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Building Maintenance', 2699.0, 'RSD', '2026-03-15', '2026-06-17',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '98a2d6c0-0005-556e-81f0-05cb67239a43', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Electricity', 3562.55, 'RSD', '2026-03-15', '2026-06-17',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '03143f23-8353-563c-b96d-c3a14d57be97', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Infostan', 5995.8, 'RSD', '2026-03-15', '2026-06-17',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '13774807-63ef-5fbc-9fa5-1f27a9288647', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Parking', 1311.11, 'RSD', '2026-03-15', '2026-06-17',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '958eda9e-e97e-57ea-86ac-7398e73df2d0', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Building Maintenance', 19345.01, 'RSD', '2026-04-15', '2026-06-17',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '958eda9e-e97e-57ea-86ac-7398e73df2d0', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Building Maintenance', 2455.19, 'RSD', '2026-04-15', '2026-06-17',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '958eda9e-e97e-57ea-86ac-7398e73df2d0', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Building Maintenance', 6959.23, 'RSD', '2026-04-15', '2026-06-17',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '958eda9e-e97e-57ea-86ac-7398e73df2d0', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Building Maintenance', 2699.0, 'RSD', '2026-04-15', '2026-06-17',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '73985f24-b576-5cf0-b909-fbd9a03b6852', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Electricity', 3280.01, 'RSD', '2026-04-15', '2026-06-17',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '75468962-91fd-5ce6-889b-c65fa2347e45', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Infostan', 5830.25, 'RSD', '2026-04-15', '2026-06-17',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '06c484e4-855a-5e74-8867-666aee0bb4ea', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Parking', 1263.17, 'RSD', '2026-04-15', '2026-06-17',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'e5c0f001-5960-5eed-8bf1-d40c0c53f08f', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Building Maintenance', 19348.67, 'RSD', '2026-05-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'e5c0f001-5960-5eed-8bf1-d40c0c53f08f', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Building Maintenance', 2198.48, 'RSD', '2026-05-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'e5c0f001-5960-5eed-8bf1-d40c0c53f08f', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Building Maintenance', 6203.67, 'RSD', '2026-05-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'e5c0f001-5960-5eed-8bf1-d40c0c53f08f', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Building Maintenance', 2699.0, 'RSD', '2026-05-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '5340f798-75f8-55ad-a252-7a15ccea1f0c', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Electricity', 3504.58, 'RSD', '2026-05-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'e2ba27d9-e29f-52cd-9c9e-119bb792fe74', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Infostan', 5733.34, 'RSD', '2026-05-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '67821dcd-15a0-5dfa-8668-9039c1a436ee', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Parking', 805.17, 'RSD', '2026-05-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '5974af41-3f23-5a7a-aab8-ba27ca04ab55', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Building Maintenance', 21386.3, 'RSD', '2026-06-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '5974af41-3f23-5a7a-aab8-ba27ca04ab55', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Building Maintenance', 3153.71, 'RSD', '2026-06-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '5974af41-3f23-5a7a-aab8-ba27ca04ab55', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Building Maintenance', 5212.88, 'RSD', '2026-06-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '5974af41-3f23-5a7a-aab8-ba27ca04ab55', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Building Maintenance', 2699.0, 'RSD', '2026-06-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '870e7975-2507-5681-a8b8-47b55f4d2620', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Electricity', 3145.48, 'RSD', '2026-06-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'bfc8c77a-205f-52b2-85f3-2d0b39933f6f', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Infostan', 5674.46, 'RSD', '2026-06-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd2061351-3b0a-5891-a868-b9d6b15ebb74', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Parking', 821.86, 'RSD', '2026-06-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '7af5f935-04d3-5397-a5df-788b73f87ce3', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Building Maintenance', 19563.98, 'RSD', '2026-07-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '7af5f935-04d3-5397-a5df-788b73f87ce3', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Building Maintenance', 5616.23, 'RSD', '2026-07-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '7af5f935-04d3-5397-a5df-788b73f87ce3', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Building Maintenance', 6284.03, 'RSD', '2026-07-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '7af5f935-04d3-5397-a5df-788b73f87ce3', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Building Maintenance', 2699.0, 'RSD', '2026-07-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '1a3fc175-417d-572c-94fe-d5075f1b9952', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Electricity', 3510.89, 'RSD', '2026-07-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '32ef317d-c6e1-5b87-a799-fefc347d302a', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Infostan', 5862.55, 'RSD', '2026-07-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd88319a0-961a-5aba-afd8-f794c1f5f53c', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Parking', 850.58, 'RSD', '2026-07-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '3dee44db-143c-5659-811a-4fcaed3a5adf', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Building Maintenance', 18665.36, 'RSD', '2026-08-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '3dee44db-143c-5659-811a-4fcaed3a5adf', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Building Maintenance', 9738.93, 'RSD', '2026-08-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '3dee44db-143c-5659-811a-4fcaed3a5adf', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Building Maintenance', 6580.22, 'RSD', '2026-08-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '3dee44db-143c-5659-811a-4fcaed3a5adf', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Building Maintenance', 17333.76, 'RSD', '2026-08-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'f24de70f-be52-5fa7-98be-2fdb15631c70', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Electricity', 3359.59, 'RSD', '2026-08-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '13049ade-2f3d-54b6-91f8-b76e96dd3679', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Infostan', 5876.11, 'RSD', '2026-08-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '91a2afe5-4cd3-5e73-b85d-91046786deb9', '795db987-07d2-515b-84cd-1656f271953d', '7c321f09-f3f6-5415-bc50-1d1b92b77e9a', 'Parking', 4058.29, 'RSD', '2026-08-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '0023ae70-50fa-5cdc-a519-e990cc72fcd7', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Kira', 2000.0, 'EUR', '2026-01-01', '2025-03-16',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'cabfc687-1138-56bd-b14d-7429543becb7', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Kira', 2000.0, 'EUR', '2026-02-01', '2025-03-16',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'b21d8f66-7d4e-50bb-8347-3c5fd429f8b3', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Kira', 2000.0, 'EUR', '2026-03-01', '2025-03-16',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'a6b6a974-605a-545b-8356-b001d47083df', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Kira', 2000.0, 'EUR', '2026-04-01', '2026-04-09',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '93688f5b-bc73-5482-b97c-1f182a7bde76', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Kira', 2000.0, 'EUR', '2026-05-01', '2026-05-05',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '75f7f503-305d-58d6-80ce-a720d6e342b3', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Kira', 2000.0, 'EUR', '2026-06-01', '2026-06-02',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '6915db9d-b227-5e7d-9aa3-1a9a0223251c', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Kira', 2000.0, 'EUR', '2026-07-01', '2026-07-06',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '7ef657c4-cf13-5e04-b746-1b41f4d1b24a', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Kira', 2000.0, 'EUR', '2026-08-01', '2026-08-11',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '08d8ea97-8a56-5e6a-8d34-bf88707a6462', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Kira', 2000.0, 'EUR', '2026-09-01', '2026-09-10',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '08180818-3009-5c6b-8c8c-85c1acbd6343', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Kira', 2000.0, 'EUR', '2026-10-01', '2026-10-13',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'dc9160bb-b5d1-50f6-bc63-46d57f53bbd2', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Building Maintenance', 16925.5, 'RSD', '2026-01-15', '2026-03-11',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'dc9160bb-b5d1-50f6-bc63-46d57f53bbd2', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Building Maintenance', 2365.48, 'RSD', '2026-01-15', '2026-03-11',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'dc9160bb-b5d1-50f6-bc63-46d57f53bbd2', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Building Maintenance', 8457.15, 'RSD', '2026-01-15', '2026-03-11',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'dc9160bb-b5d1-50f6-bc63-46d57f53bbd2', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Building Maintenance', 3094.4, 'RSD', '2026-01-15', '2026-03-11',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd957c38b-78ab-5242-85ce-613e4559a65f', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Electricity', 3967.0, 'RSD', '2026-01-15', '2026-03-11',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '3a9f951a-3caa-5395-b21f-bbaac6109fca', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Infostan', 4983.45, 'RSD', '2026-01-15', '2026-03-11',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'f1ff5315-472a-53a4-8280-4996bf73103a', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Parking', 802.75, 'RSD', '2026-01-15', '2026-03-11',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'f1ff5315-472a-53a4-8280-4996bf73103a', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Parking', 2290.0, 'RSD', '2026-01-15', '2026-03-11',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '81576db8-055f-5319-aa68-53cca4a23974', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Building Maintenance', 16922.98, 'RSD', '2026-02-15', '2026-04-09',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '81576db8-055f-5319-aa68-53cca4a23974', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Building Maintenance', 5140.45, 'RSD', '2026-02-15', '2026-04-09',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '81576db8-055f-5319-aa68-53cca4a23974', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Building Maintenance', 5399.86, 'RSD', '2026-02-15', '2026-04-09',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '81576db8-055f-5319-aa68-53cca4a23974', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Building Maintenance', 3094.4, 'RSD', '2026-02-15', '2026-04-09',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '4f46002a-7b70-52ea-a8d4-4deb5938498c', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Electricity', 5024.74, 'RSD', '2026-02-15', '2026-04-09',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '92feb32d-66c2-5af2-a029-d5ea63734335', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Infostan', 4888.62, 'RSD', '2026-02-15', '2026-04-09',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '26469b08-8a61-582c-a7af-ba34279ed5f9', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Parking', 4107.04, 'RSD', '2026-02-15', '2026-04-09',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '26469b08-8a61-582c-a7af-ba34279ed5f9', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Parking', 2289.32, 'RSD', '2026-02-15', '2026-04-09',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'f75b6ad6-70f3-5c53-93c3-ddc458f06ad7', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Building Maintenance', 16928.6, 'RSD', '2026-03-15', '2026-05-05',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'f75b6ad6-70f3-5c53-93c3-ddc458f06ad7', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Building Maintenance', 3513.8, 'RSD', '2026-03-15', '2026-05-05',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'f75b6ad6-70f3-5c53-93c3-ddc458f06ad7', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Building Maintenance', 9707.01, 'RSD', '2026-03-15', '2026-05-05',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'f75b6ad6-70f3-5c53-93c3-ddc458f06ad7', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Building Maintenance', 3094.4, 'RSD', '2026-03-15', '2026-05-05',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '69a7c823-b250-5769-8913-dcd153236712', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Electricity', 5633.33, 'RSD', '2026-03-15', '2026-05-05',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '03b2ce3e-7567-5f6a-84b3-dec5eb26221c', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Infostan', 4733.59, 'RSD', '2026-03-15', '2026-05-05',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '45fd6834-6ac2-5939-b423-c245da9c0cc2', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Parking', 1311.11, 'RSD', '2026-03-15', '2026-05-05',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '45fd6834-6ac2-5939-b423-c245da9c0cc2', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Parking', 2290.08, 'RSD', '2026-03-15', '2026-05-05',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '3cb73b18-f94e-5713-bfd4-b2d4a5a3973e', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Building Maintenance', 16922.1, 'RSD', '2026-04-15', '2026-06-02',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '3cb73b18-f94e-5713-bfd4-b2d4a5a3973e', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Building Maintenance', 6618.46, 'RSD', '2026-04-15', '2026-06-02',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '3cb73b18-f94e-5713-bfd4-b2d4a5a3973e', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Building Maintenance', 9878.38, 'RSD', '2026-04-15', '2026-06-02',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '3cb73b18-f94e-5713-bfd4-b2d4a5a3973e', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Building Maintenance', 3094.4, 'RSD', '2026-04-15', '2026-06-02',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'b84601c1-011c-58da-b358-f5d77999f4dc', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Electricity', 5014.44, 'RSD', '2026-04-15', '2026-06-02',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '9e9185c8-328b-574c-acef-14794f23b36c', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Infostan', 4568.04, 'RSD', '2026-04-15', '2026-06-02',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'b7447f13-6645-5a06-92da-cb3bba30ef4c', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Parking', 1263.17, 'RSD', '2026-04-15', '2026-06-02',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'b7447f13-6645-5a06-92da-cb3bba30ef4c', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Parking', 2289.2, 'RSD', '2026-04-15', '2026-06-02',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd3b61618-4a06-50ce-846e-7cd00b1b70ec', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Building Maintenance', 16925.31, 'RSD', '2026-05-15', '2026-07-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd3b61618-4a06-50ce-846e-7cd00b1b70ec', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Building Maintenance', 3851.14, 'RSD', '2026-05-15', '2026-07-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd3b61618-4a06-50ce-846e-7cd00b1b70ec', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Building Maintenance', 8008.75, 'RSD', '2026-05-15', '2026-07-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd3b61618-4a06-50ce-846e-7cd00b1b70ec', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Building Maintenance', 3094.4, 'RSD', '2026-05-15', '2026-07-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '880cf77d-8acb-5282-9e20-09783af19dc9', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Electricity', 4977.22, 'RSD', '2026-05-15', '2026-07-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '49e5803e-8e91-5d13-9e30-93c789f0da73', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Infostan', 4484.55, 'RSD', '2026-05-15', '2026-07-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '62801e63-1e7b-553d-81a7-e18ba9430cb0', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Parking', 805.17, 'RSD', '2026-05-15', '2026-07-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '62801e63-1e7b-553d-81a7-e18ba9430cb0', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Parking', 2289.64, 'RSD', '2026-05-15', '2026-07-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '6314353a-f0ef-5d45-b039-9e2c0fcf63fe', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Building Maintenance', 18665.79, 'RSD', '2026-06-15', '2026-08-11',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '6314353a-f0ef-5d45-b039-9e2c0fcf63fe', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Building Maintenance', 4962.52, 'RSD', '2026-06-15', '2026-08-11',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '6314353a-f0ef-5d45-b039-9e2c0fcf63fe', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Building Maintenance', 6750.47, 'RSD', '2026-06-15', '2026-08-11',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '6314353a-f0ef-5d45-b039-9e2c0fcf63fe', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Building Maintenance', 3094.4, 'RSD', '2026-06-15', '2026-08-11',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'ad64eb1c-50aa-5f7e-a07f-9db377dfb5d8', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Electricity', 5270.23, 'RSD', '2026-06-15', '2026-08-11',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd49cb8a9-2e21-58f8-be28-db73cd202b65', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Infostan', 4226.19, 'RSD', '2026-06-15', '2026-08-11',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'fad6900b-2526-5187-84ca-2a21b89d54bd', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Parking', 821.86, 'RSD', '2026-06-15', '2026-08-11',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'fad6900b-2526-5187-84ca-2a21b89d54bd', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Parking', 2570.97, 'RSD', '2026-06-15', '2026-08-11',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '41918e1e-cc42-5b8e-a94b-3d0a57a93915', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Building Maintenance', 16842.86, 'RSD', '2026-07-15', '2026-09-11',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '41918e1e-cc42-5b8e-a94b-3d0a57a93915', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Building Maintenance', 10467.87, 'RSD', '2026-07-15', '2026-09-11',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '41918e1e-cc42-5b8e-a94b-3d0a57a93915', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Building Maintenance', 7548.93, 'RSD', '2026-07-15', '2026-09-11',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '41918e1e-cc42-5b8e-a94b-3d0a57a93915', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Building Maintenance', 3094.4, 'RSD', '2026-07-15', '2026-09-11',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '2ac73264-171d-5480-b5e6-86c98f3d9a84', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Electricity', 5817.71, 'RSD', '2026-07-15', '2026-09-11',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'a6089c64-b597-5a5a-96fc-70a7ef60ef8c', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Infostan', 4414.28, 'RSD', '2026-07-15', '2026-09-11',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '4364d042-8c5f-508d-b82d-6278d3aa5835', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Parking', 850.58, 'RSD', '2026-07-15', '2026-09-11',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '4364d042-8c5f-508d-b82d-6278d3aa5835', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Parking', 2570.97, 'RSD', '2026-07-15', '2026-09-11',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd308a1b4-67f6-5ab5-be55-6bc0f0cccaf8', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Building Maintenance', 15944.82, 'RSD', '2026-08-15', '2026-10-13',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd308a1b4-67f6-5ab5-be55-6bc0f0cccaf8', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Building Maintenance', 17011.49, 'RSD', '2026-08-15', '2026-10-13',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd308a1b4-67f6-5ab5-be55-6bc0f0cccaf8', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Building Maintenance', 8301.08, 'RSD', '2026-08-15', '2026-10-13',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd308a1b4-67f6-5ab5-be55-6bc0f0cccaf8', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Building Maintenance', 3094.4, 'RSD', '2026-08-15', '2026-10-13',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'b3e5f4a3-f6bd-505f-a95d-ff1f6a4920c2', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Electricity', 5360.26, 'RSD', '2026-08-15', '2026-10-13',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '706027b9-a43b-5fe9-b1ef-d4afddaa55f6', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Infostan', 4427.84, 'RSD', '2026-08-15', '2026-10-13',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '4a5f5699-0280-50b2-b6e8-199b2b7940b9', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Parking', 4058.29, 'RSD', '2026-08-15', '2026-10-13',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '4a5f5699-0280-50b2-b6e8-199b2b7940b9', '992ab199-2589-5896-816a-963caadd041e', 'f6c8a07b-65ed-55b8-ab18-49f949e1f6d3', 'Parking', 2570.41, 'RSD', '2026-08-15', '2026-10-13',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '743a4e05-6760-5c1d-8c1a-10d6269dc4be', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Kira', 2500.0, 'EUR', '2026-01-01', '2026-01-08',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'adec8200-fff2-5ba1-a4ea-e402e6b741a3', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Kira', 2500.0, 'EUR', '2026-02-01', '2026-02-12',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '8a8a07d7-24d1-5691-acfb-2329e6741839', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Kira', 2500.0, 'EUR', '2026-03-01', '2026-03-06',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'f2dac4ef-c8dd-56ff-b74e-fc32134a0489', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Kira', 2500.0, 'EUR', '2026-04-01', '2026-04-06',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'c24bac87-f464-5584-9c35-25883a7b19c8', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Kira', 2500.0, 'EUR', '2026-05-01', '2026-05-06',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'd2b9dfdd-8604-573e-98ad-1719c68a6609', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Kira', 2500.0, 'EUR', '2026-06-01', '2026-06-08',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '787a201f-c8d9-5e65-a34d-a2303227ca1c', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Kira', 2500.0, 'EUR', '2026-07-01', '2026-07-07',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'c6d4be24-1425-5d08-bbd3-05daf946f68a', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Kira', 2500.0, 'EUR', '2026-08-01', '2026-08-04',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '3c8b0e17-482f-5f0d-b391-47870cafc73a', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Kira', 2500.0, 'EUR', '2026-09-01', '2026-09-08',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '1dc49bcd-a084-5027-b7fa-e2383d9193e0', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Kira', 2500.0, 'EUR', '2026-10-01', '2026-10-14',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'fb0de124-78dc-570b-86ad-261d6dc31ca9', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Building Maintenance', 6427.91, 'RSD', '2026-01-15', '2026-03-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'f8ff6d80-8967-5507-82b5-403bcae70329', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 679.07, 'RSD', '2026-01-15', '2026-03-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'f8ff6d80-8967-5507-82b5-403bcae70329', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 679.07, 'RSD', '2026-01-15', '2026-03-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '6ed4f3aa-780c-5a35-9522-4de2a60a8b99', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Electricity', 4208.86, 'RSD', '2026-01-15', '2026-03-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '70e2de0c-df80-53d3-bc54-1013f267a2b9', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Infostan', 20727.19, 'RSD', '2026-01-15', '2026-03-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'f8ff6d80-8967-5507-82b5-403bcae70329', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 950.89, 'RSD', '2026-01-15', '2026-03-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'f8ff6d80-8967-5507-82b5-403bcae70329', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 950.89, 'RSD', '2026-01-15', '2026-03-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'faaa0dd1-644a-5ea0-a462-a7e57fd740b9', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Building Maintenance', 5750.78, 'RSD', '2026-02-15', '2026-03-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '01f931f4-88aa-533e-b4b7-ff1f72782d58', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 631.98, 'RSD', '2026-02-15', '2026-03-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '01f931f4-88aa-533e-b4b7-ff1f72782d58', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 631.98, 'RSD', '2026-02-15', '2026-03-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'ecc55d84-d14d-55fa-a153-c98fbc14d802', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Electricity', 3612.56, 'RSD', '2026-02-15', '2026-03-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'fe0d674e-dc43-5192-a9f7-ac8697facfeb', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Infostan', 25352.63, 'RSD', '2026-02-15', '2026-03-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '01f931f4-88aa-533e-b4b7-ff1f72782d58', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 1005.61, 'RSD', '2026-02-15', '2026-03-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '01f931f4-88aa-533e-b4b7-ff1f72782d58', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 1005.61, 'RSD', '2026-02-15', '2026-03-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'faaa0dd1-644a-5ea0-a462-a7e57fd740b9', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Building Maintenance', 2131.65, 'RSD', '2026-02-15', '2026-03-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '01f931f4-88aa-533e-b4b7-ff1f72782d58', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 379.86, 'RSD', '2026-02-15', '2026-03-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '01f931f4-88aa-533e-b4b7-ff1f72782d58', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 379.86, 'RSD', '2026-02-15', '2026-03-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'c5a3dff0-40bf-5e61-bc84-a5ef75d551be', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Building Maintenance', 5751.82, 'RSD', '2026-03-15', '2026-05-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '516a2f28-b697-5050-b366-84c9c3252f95', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 624.25, 'RSD', '2026-03-15', '2026-05-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '516a2f28-b697-5050-b366-84c9c3252f95', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 624.25, 'RSD', '2026-03-15', '2026-05-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '9e09ccba-cd6b-5a1f-a2fb-9173c3575e9e', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Electricity', 3706.92, 'RSD', '2026-03-15', '2026-05-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'e3a5df50-85c7-5da2-a6cd-55ad5c14d6c5', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Infostan', 20178.46, 'RSD', '2026-03-15', '2026-05-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '516a2f28-b697-5050-b366-84c9c3252f95', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 1261.63, 'RSD', '2026-03-15', '2026-05-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '516a2f28-b697-5050-b366-84c9c3252f95', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 1261.63, 'RSD', '2026-03-15', '2026-05-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'fb672274-0e89-51a2-9960-b2e15e56fc40', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Building Maintenance', 5751.35, 'RSD', '2026-04-15', '2026-06-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '14e9d1ed-84b9-585b-9c96-2e9251b0dc86', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 592.86, 'RSD', '2026-04-15', '2026-06-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '14e9d1ed-84b9-585b-9c96-2e9251b0dc86', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 592.86, 'RSD', '2026-04-15', '2026-06-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'f7d10028-3cdc-58ad-bd78-9e77f30fc29a', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Electricity', 3922.0, 'RSD', '2026-04-15', '2026-06-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '7d9dbe1d-1102-5353-b036-536f7701b5ca', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Infostan', 18006.64, 'RSD', '2026-04-15', '2026-06-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '14e9d1ed-84b9-585b-9c96-2e9251b0dc86', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 968.56, 'RSD', '2026-04-15', '2026-06-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '14e9d1ed-84b9-585b-9c96-2e9251b0dc86', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 968.56, 'RSD', '2026-04-15', '2026-06-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '09181401-5d77-5615-8258-4cb65fcc354c', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Building Maintenance', 5751.58, 'RSD', '2026-05-15', '2026-07-07',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '7e8e3fb9-fa76-5a54-b9b1-c42886624698', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 665.35, 'RSD', '2026-05-15', '2026-07-07',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '7e8e3fb9-fa76-5a54-b9b1-c42886624698', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 665.35, 'RSD', '2026-05-15', '2026-07-07',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '23042345-27a5-5f24-a2db-0136a1116249', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Electricity', 3792.44, 'RSD', '2026-05-15', '2026-07-07',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd960c720-4ba9-5897-9baa-3916cf045fe3', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Infostan', 15131.97, 'RSD', '2026-05-15', '2026-07-07',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '7e8e3fb9-fa76-5a54-b9b1-c42886624698', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 1000.49, 'RSD', '2026-05-15', '2026-07-07',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '7e8e3fb9-fa76-5a54-b9b1-c42886624698', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 1000.49, 'RSD', '2026-05-15', '2026-07-07',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '09181401-5d77-5615-8258-4cb65fcc354c', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Building Maintenance', 2481.3, 'RSD', '2026-05-15', '2026-07-07',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '7e8e3fb9-fa76-5a54-b9b1-c42886624698', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 150.0, 'RSD', '2026-05-15', '2026-07-07',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '7e8e3fb9-fa76-5a54-b9b1-c42886624698', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 150.0, 'RSD', '2026-05-15', '2026-07-07',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd265edc5-ec41-5c93-8035-8d9770da2533', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Building Maintenance', 5749.24, 'RSD', '2026-06-15', '2026-08-04',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'e0cdfea6-e38a-5c33-bc3f-7393dbe4f5da', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 592.64, 'RSD', '2026-06-15', '2026-08-04',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'e0cdfea6-e38a-5c33-bc3f-7393dbe4f5da', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 592.64, 'RSD', '2026-06-15', '2026-08-04',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '10bfbafc-6a8a-5606-8eb1-cbd431a3e0e5', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Electricity', 4616.99, 'RSD', '2026-06-15', '2026-08-04',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '93f4beba-4a78-5cc8-a998-2963a110c8dc', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Infostan', 11140.27, 'RSD', '2026-06-15', '2026-08-04',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'e0cdfea6-e38a-5c33-bc3f-7393dbe4f5da', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 978.8, 'RSD', '2026-06-15', '2026-08-04',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'e0cdfea6-e38a-5c33-bc3f-7393dbe4f5da', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 978.8, 'RSD', '2026-06-15', '2026-08-04',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '00f7f3be-715a-57bc-a670-410195a89bfc', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Building Maintenance', 5750.53, 'RSD', '2026-07-15', '2026-09-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '11184a0f-f9e7-5a92-9927-20fc6210517b', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 624.12, 'RSD', '2026-07-15', '2026-09-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '11184a0f-f9e7-5a92-9927-20fc6210517b', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 624.12, 'RSD', '2026-07-15', '2026-09-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '450bf282-2126-5023-b8df-96a7af84e39f', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Electricity', 5184.23, 'RSD', '2026-07-15', '2026-09-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '32d38a11-a8cd-5e9c-bacf-e5442828af44', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Infostan', 13012.83, 'RSD', '2026-07-15', '2026-09-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '11184a0f-f9e7-5a92-9927-20fc6210517b', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 1065.85, 'RSD', '2026-07-15', '2026-09-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '11184a0f-f9e7-5a92-9927-20fc6210517b', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 1065.85, 'RSD', '2026-07-15', '2026-09-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '3cdcdee0-cb19-5d7b-8ee6-f6cd96162e3d', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Building Maintenance', 5812.37, 'RSD', '2026-08-15', '2026-10-14',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '38cf03b3-0dff-551e-b60e-0716fea8c4b6', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 593.18, 'RSD', '2026-08-15', '2026-10-14',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '38cf03b3-0dff-551e-b60e-0716fea8c4b6', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 593.18, 'RSD', '2026-08-15', '2026-10-14',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '7f34b458-c4d6-52b1-8d4d-1fa54e0f36e0', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Electricity', 5509.48, 'RSD', '2026-08-15', '2026-10-14',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '8b207e40-1803-5356-8eb7-29d83ac5ec64', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Infostan', 11229.72, 'RSD', '2026-08-15', '2026-10-14',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '38cf03b3-0dff-551e-b60e-0716fea8c4b6', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 938.41, 'RSD', '2026-08-15', '2026-10-14',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '38cf03b3-0dff-551e-b60e-0716fea8c4b6', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 938.41, 'RSD', '2026-08-15', '2026-10-14',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '3cdcdee0-cb19-5d7b-8ee6-f6cd96162e3d', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Building Maintenance', 379.86, 'RSD', '2026-08-15', '2026-10-14',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '38cf03b3-0dff-551e-b60e-0716fea8c4b6', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 2481.3, 'RSD', '2026-08-15', '2026-10-14',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '38cf03b3-0dff-551e-b60e-0716fea8c4b6', 'f9cf07d9-44ef-5d9a-8723-4b0397d91dbf', '71fa55d9-2016-5ead-8304-d3dc02c1c553', 'Parking', 379.86, 'RSD', '2026-08-15', '2026-10-14',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'cacdd293-10a4-5f51-a995-ae6983269980', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Kira', 2100.0, 'EUR', '2026-01-01', '2026-02-01',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '47294301-8420-5434-9ff2-111ade763f58', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Kira', 2100.0, 'EUR', '2026-02-01', '2026-02-01',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'ef84c230-e208-5991-bde8-2f5487ee8454', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Kira', 2100.0, 'EUR', '2026-03-01', '2026-02-01',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'f4bac391-1a0a-5504-a4f2-c4a9c904d328', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Kira', 2100.0, 'EUR', '2026-04-01', '2026-02-01',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '7aa6de5e-37b9-5819-98a8-0adf1e5a5457', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Kira', 2100.0, 'EUR', '2026-05-01', '2026-02-01',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '84c78663-0868-58a3-9fd3-701c55554613', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Kira', 2000.0, 'EUR', '2026-07-01', '2026-06-24',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'a35fcf91-c41f-5c96-ae99-ac42054e9691', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Kira', 2000.0, 'EUR', '2026-08-01', '2026-07-29',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'cd1067cf-f6c2-547a-abcf-f9d09232d831', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Kira', 2000.0, 'EUR', '2026-09-01', '2026-07-29',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '617e3999-7405-542a-a7ae-0da4c7984a2b', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Kira', 2000.0, 'EUR', '2026-10-01', '2026-09-25',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '857a7981-a941-5141-a36d-f7a3add2e23c', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Kira', 2000.0, 'EUR', '2026-11-01', '2026-09-25',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'cc37797a-51c4-5110-8e4b-213875b19c7d', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Building Maintenance', 20535.62, 'RSD', '2026-01-15', '2026-02-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'b11733c3-a2ad-5b20-ab12-1963302132a7', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Electricity', 3391.98, 'RSD', '2026-01-15', '2026-02-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '7c1abced-cc2b-54c5-9075-1a464527419e', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Infostan', 20643.17, 'RSD', '2026-01-15', '2026-02-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '31d5ec92-8845-508b-8de8-52866709b19f', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Parking', 1183.24, 'RSD', '2026-01-15', '2026-02-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '1ed27b3c-47d2-52b5-a4fd-1ebdfe87c5b1', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Building Maintenance', 20532.76, 'RSD', '2026-02-15', '2026-04-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'a6c28752-56f5-59f8-b281-f4e35b0354ea', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Electricity', 14013.68, 'RSD', '2026-02-15', '2026-04-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '68f12c33-6ae6-54a8-81f1-448147c9f124', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Infostan', 24630.04, 'RSD', '2026-02-15', '2026-04-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '630e4db0-a0cc-5ea3-aa79-536172b00aff', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Parking', 1290.15, 'RSD', '2026-02-15', '2026-04-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '2c82486a-1c17-58c6-a902-861bf03fe710', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Building Maintenance', 20536.23, 'RSD', '2026-03-15', '2026-05-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'f91b3ef4-af4f-58f0-b582-bd714f763728', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Electricity', 12009.96, 'RSD', '2026-03-15', '2026-05-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '332cbea5-2b07-5ee3-bd70-c026f4cf80b1', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Infostan', 19343.25, 'RSD', '2026-03-15', '2026-05-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'a5631236-6a05-58ab-9097-a29f779652dd', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Parking', 1601.0, 'RSD', '2026-03-15', '2026-05-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'bc581b19-d861-5ac4-99d3-595fd2c2f757', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Building Maintenance', 20531.76, 'RSD', '2026-04-15', '2026-06-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'ec43d587-ba16-5a71-b171-56cef0210d7b', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Electricity', 8167.65, 'RSD', '2026-04-15', '2026-06-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'f11a9c51-0706-5c1e-91cc-588e209c946d', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Infostan', 17807.05, 'RSD', '2026-04-15', '2026-06-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd1634b9d-1d46-52c9-bd39-d353aad512c4', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Parking', 1349.98, 'RSD', '2026-04-15', '2026-06-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'a80704fa-9a5a-5481-a962-d3ad9ef1b034', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Building Maintenance', 20535.41, 'RSD', '2026-05-15', '2026-06-15',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'e1d96b28-0047-5f36-abd3-5eda4f57f287', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Electricity', 4438.59, 'RSD', '2026-05-15', '2026-06-15',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '0e820838-bf8e-50cf-9246-66c15f400795', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Infostan', 13518.32, 'RSD', '2026-05-15', '2026-06-15',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'bd4e381e-499d-5178-8b43-62b6fa04a390', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Parking', 1376.56, 'RSD', '2026-05-15', '2026-06-15',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '7b1e6495-9601-5b5c-9f8b-fe4d7e72bfaf', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Building Maintenance', 4789.77, 'RSD', '2026-06-15', '2026-09-25',
        'paid', 'Oransal kısmi ödeme (4789.77 RSD ödendi)', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'bdd6b735-3805-58a3-9935-7bd323bea77a', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Building Maintenance (Kalan)', 15737.82, 'RSD', '2026-06-15', NULL,
        'pending', 'Kalan borç bakiyesi (15737.82 RSD)', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '8c2ab5e8-7edc-5324-aa12-8541223f148f', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Electricity', 1530.99, 'RSD', '2026-06-15', '2026-09-25',
        'paid', 'Oransal kısmi ödeme (1530.99 RSD ödendi)', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '3fe71e01-4c34-584f-a8c6-a2284bb01e1b', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Electricity (Kalan)', 5030.42, 'RSD', '2026-06-15', NULL,
        'pending', 'Kalan borç bakiyesi (5030.42 RSD)', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'a3322f01-2f97-5671-8028-776b2659b381', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Infostan', 1635.13, 'RSD', '2026-06-15', '2026-09-25',
        'paid', 'Oransal kısmi ödeme (1635.13 RSD ödendi)', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '1668b981-ae2b-5fe2-9b23-003e954ee634', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Infostan (Kalan)', 5372.59, 'RSD', '2026-06-15', NULL,
        'pending', 'Kalan borç bakiyesi (5372.59 RSD)', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'a8ac03b5-8801-569c-ae66-256f1d49706e', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Parking', 302.89, 'RSD', '2026-06-15', '2026-09-25',
        'paid', 'Oransal kısmi ödeme (302.89 RSD ödendi)', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '5b82577c-6009-5bbd-86bf-24425d96bd97', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Parking (Kalan)', 995.23, 'RSD', '2026-06-15', NULL,
        'pending', 'Kalan borç bakiyesi (995.23 RSD)', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '2259f39e-c1fb-5eab-a04d-d5b9b47e0980', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Building Maintenance', 20531.94, 'RSD', '2026-07-15', '2026-08-28',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'b3eee0b3-5104-5ef6-8d22-e65a46774de7', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Electricity', 8525.48, 'RSD', '2026-07-15', '2026-08-28',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '52a746de-b1c5-53d0-8e53-8ae5124bc3d5', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Infostan', 7311.15, 'RSD', '2026-07-15', '2026-08-28',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '64579b1b-157b-5619-a898-e3b64287faaa', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Parking', 1299.18, 'RSD', '2026-07-15', '2026-08-28',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '294336f8-d51b-5c95-9af0-93c5a79ea9d1', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Building Maintenance', 20524.88, 'RSD', '2026-08-15', '2026-09-25',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '13872302-31a8-5dd8-a0b8-750bf73801d6', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Electricity', 3565.71, 'RSD', '2026-08-15', '2026-09-25',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '2c57865f-82e8-576d-bd48-21e7e9236a75', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Infostan', 7143.68, 'RSD', '2026-08-15', '2026-09-25',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'cc7becd6-6488-570f-a3e4-c8980cbb59b4', '6308167e-af32-53bb-9c22-df5efa478fa1', 'b2e4d5fa-5391-5e9c-bccc-ff76152bc36a', 'Parking', 1235.35, 'RSD', '2026-08-15', '2026-09-25',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'ee5e390e-1599-5c4a-80d1-b5e29ba01d9a', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Kira', 3200.0, 'EUR', '2026-01-01', '2026-01-08',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'c5384bdc-7d16-543d-ad6c-050176003fef', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Kira', 3200.0, 'EUR', '2026-02-01', '2026-02-13',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '3ed29da4-3c34-5023-9887-9c512e182146', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Kira', 3200.0, 'EUR', '2026-03-01', '2026-02-27',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'e7222c09-716d-5972-a0a5-fce59aac6a31', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Kira', 3200.0, 'EUR', '2026-04-01', '2026-04-06',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'a360d483-2f7a-51a9-93d3-5acef28e36c3', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Kira', 3200.0, 'EUR', '2026-05-01', '2026-05-04',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '836ded88-c4c2-5991-968f-0e6ce98e98d1', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Kira', 3200.0, 'EUR', '2026-06-01', '2026-06-03',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'eb72b99b-3cd3-50a9-8498-d388d40e98ab', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Kira', 3200.0, 'EUR', '2026-07-01', '2026-07-01',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '00109534-8159-5271-8ef0-761ac1b5150e', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Kira', 3200.0, 'EUR', '2026-08-01', '2026-08-04',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '4682b64b-00de-5e16-8e55-e3b4673db2f0', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Kira', 3200.0, 'EUR', '2026-09-01', '2026-08-04',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'b2643650-619b-5480-9ffb-108daa38cb3d', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Kira', 3200.0, 'EUR', '2026-10-01', '2026-08-04',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'cf7837d9-6fc6-54ed-9e25-e97fe0e2af17', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Building Maintenance', 32978.66, 'RSD', '2026-01-15', '2026-02-27',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '3302f943-c4f6-5fe9-804d-d7bd9996dbd7', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Electricity', 3718.32, 'RSD', '2026-01-15', '2026-02-27',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '903c3082-a083-5ee6-9671-f8cd4f4fb751', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Infostan', 32815.21, 'RSD', '2026-01-15', '2026-02-27',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'b203e567-fceb-504a-be9f-f73c9e26740d', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Parking', 1183.24, 'RSD', '2026-01-15', '2026-02-27',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'b203e567-fceb-504a-be9f-f73c9e26740d', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Parking', 1183.24, 'RSD', '2026-01-15', '2026-02-27',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '5f1ac524-7f2f-5609-99d6-8835f3a29d17', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Building Maintenance', 32974.08, 'RSD', '2026-02-15', '2026-04-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '8c66420c-1ad4-5d64-b765-8d5dacab6294', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Electricity', 7627.25, 'RSD', '2026-02-15', '2026-04-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '8518f809-ce58-5bab-b2b6-85e849281abc', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Infostan', 36575.62, 'RSD', '2026-02-15', '2026-04-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '2c5cc02a-a0ff-5e99-a65b-37bd2e87d4f3', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Parking', 1290.15, 'RSD', '2026-02-15', '2026-04-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '2c5cc02a-a0ff-5e99-a65b-37bd2e87d4f3', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Parking', 1290.15, 'RSD', '2026-02-15', '2026-04-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '51703360-7fb9-5394-a21d-cb8a2b7f2976', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Building Maintenance', 32979.64, 'RSD', '2026-03-15', '2026-05-04',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'cc0ae896-8cee-502e-baed-f77be1c23167', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Electricity', 9748.07, 'RSD', '2026-03-15', '2026-05-04',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '0d0eed94-eb42-555f-846d-17a666617149', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Infostan', 28171.2, 'RSD', '2026-03-15', '2026-05-04',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd570c233-d940-5616-ae3c-ebde5acbf7e4', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Parking', 1601.0, 'RSD', '2026-03-15', '2026-05-04',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd570c233-d940-5616-ae3c-ebde5acbf7e4', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Parking', 1601.0, 'RSD', '2026-03-15', '2026-05-04',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'dcaecf42-c839-5fcc-904c-e3a3adf4cbab', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Building Maintenance', 32972.47, 'RSD', '2026-04-15', '2026-06-03',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd1094d49-74f0-5d73-a421-d54ff452514c', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Electricity', 9141.6, 'RSD', '2026-04-15', '2026-06-03',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '577a1829-e80b-56c9-bb89-8cc47cb76265', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Infostan', 26141.01, 'RSD', '2026-04-15', '2026-06-03',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '1e762b1d-4120-5447-9f93-8d239d0d18b7', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Parking', 1349.98, 'RSD', '2026-04-15', '2026-06-03',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '1e762b1d-4120-5447-9f93-8d239d0d18b7', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Parking', 1349.98, 'RSD', '2026-04-15', '2026-06-03',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '3dc9e36b-4567-5524-b1ac-f04ce9406ab6', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Building Maintenance', 32978.32, 'RSD', '2026-05-15', '2026-07-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '32804c6e-5c0e-5163-acde-e986f6a14120', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Electricity', 9864.95, 'RSD', '2026-05-15', '2026-07-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'e5ab22fd-bb01-5286-a362-036ec801822a', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Infostan', 20792.24, 'RSD', '2026-05-15', '2026-07-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '96b7430d-e45c-5650-95ee-29d69e5300cc', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Parking', 1376.56, 'RSD', '2026-05-15', '2026-07-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '96b7430d-e45c-5650-95ee-29d69e5300cc', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Parking', 1376.56, 'RSD', '2026-05-15', '2026-07-01',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'cf5fe7dd-1d10-5fad-a880-6cd0693e4a59', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Building Maintenance', 32965.77, 'RSD', '2026-06-15', '2026-08-04',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '04c79fb3-4ea4-5aa8-ba45-7ec025ab9c48', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Electricity', 8297.39, 'RSD', '2026-06-15', '2026-08-04',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'c44d0d58-1b4d-531d-a609-ce8db9555eec', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Infostan', 11297.12, 'RSD', '2026-06-15', '2026-08-04',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd6b11636-1829-5a81-a3c9-295c8f523773', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Parking', 1298.12, 'RSD', '2026-06-15', '2026-08-04',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd6b11636-1829-5a81-a3c9-295c8f523773', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Parking', 1298.12, 'RSD', '2026-06-15', '2026-08-04',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '78ffad4a-84e6-506c-8c40-f02c8ddf7fad', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Building Maintenance', 32972.76, 'RSD', '2026-07-15', '2026-09-10',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'dd206f4b-4299-58f4-bd91-7383472be5fd', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Electricity', 8800.79, 'RSD', '2026-07-15', '2026-09-10',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '92000a06-6397-5be8-b9fd-36e861f572ff', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Infostan', 11777.22, 'RSD', '2026-07-15', '2026-09-10',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '065d8701-3a4a-553a-9300-7417b288aaf7', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Parking', 1299.18, 'RSD', '2026-07-15', '2026-09-10',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '065d8701-3a4a-553a-9300-7417b288aaf7', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Parking', 1299.18, 'RSD', '2026-07-15', '2026-09-10',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '47d545cd-1061-566c-8f51-3361d19eab5d', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Building Maintenance', 32961.42, 'RSD', '2026-08-15', '2026-10-07',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '7cb9675d-587c-58df-a059-40634705892e', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Electricity', 12469.56, 'RSD', '2026-08-15', '2026-10-07',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '13121ed0-3731-519e-9aaf-3a5cfbdf4bd6', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Infostan', 11512.97, 'RSD', '2026-08-15', '2026-10-07',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'b9d08611-13e7-5788-9e51-ad8d6b817010', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Parking', 1235.35, 'RSD', '2026-08-15', '2026-10-07',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'b9d08611-13e7-5788-9e51-ad8d6b817010', '47013784-dd68-567f-942a-90c43141820a', 'cb25757e-2763-5330-8354-582458caddfe', 'Parking', 1235.35, 'RSD', '2026-08-15', '2026-10-07',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '3c08399e-b7dd-5464-bc2f-f57f54ccca63', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Kira', 1200.0, 'EUR', '2026-01-01', '2026-01-10',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'a1356ff0-f370-56f8-8566-20b9f99f63e6', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Kira', 1200.0, 'EUR', '2026-02-01', '2026-02-04',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'f7f145ec-226f-5ba1-b855-7c348e152581', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Kira', 1200.0, 'EUR', '2026-03-01', '2026-03-11',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'ddf61fe3-dc89-5bc6-860f-ecf15c7e0e38', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Kira', 1000.0, 'EUR', '2026-04-01', '2026-03-27',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '2f983419-2406-57c8-be86-631e777e3c4e', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Kira', 1000.0, 'EUR', '2026-05-01', '2026-04-28',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '461d79af-2466-5c44-b118-2b128e77460b', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Kira', 1000.0, 'EUR', '2026-06-01', '2026-05-29',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '6fe990bb-9e5e-5729-b560-a9286c736a3d', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Kira', 1000.0, 'EUR', '2026-07-01', '2026-06-29',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '51a8fdb6-7a0a-5d40-b051-0c17d4ecb3cb', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Kira', 1000.0, 'EUR', '2026-08-01', '2026-08-11',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '35701685-e07f-5250-b3cf-24879f788c62', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Kira', 1000.0, 'EUR', '2026-09-01', '2026-09-08',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '6995e040-7886-5423-94d9-4eb9f2ce3958', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Kira', 1000.0, 'EUR', '2026-10-01', '2026-10-08',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '6b671fd6-3af3-50d8-857e-ba67231032a0', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Building Maintenance', 12286.53, 'RSD', '2026-01-15', '2026-03-11',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'e06bb559-0669-5bd5-aa7f-33f24610d159', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Electricity', 3000.0, 'RSD', '2026-01-15', '2026-03-11',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '727b3153-e51c-5d2e-b72a-b40735b65a90', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Infostan', 9459.07, 'RSD', '2026-01-15', '2026-03-11',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'b78a0c2c-918e-546b-aef9-40aed76b312b', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Parking', 1183.24, 'RSD', '2026-01-15', '2026-03-11',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '448faee0-abd1-5626-916c-482d2f5fbcfd', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Building Maintenance', 12284.83, 'RSD', '2026-02-15', '2026-03-27',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '74d61754-91d4-57dd-a6c6-c0bdcccd0234', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Electricity', 3000.0, 'RSD', '2026-02-15', '2026-03-27',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'a5aab96c-33f4-5497-8c4c-20e1dfde618a', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Infostan', 10877.42, 'RSD', '2026-02-15', '2026-03-27',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '38fee977-32f7-5d26-b154-8eee7c40d7e0', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Parking', 1290.15, 'RSD', '2026-02-15', '2026-03-27',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'a227c6a4-a0fe-5bbb-bfe2-b874d7222a61', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Building Maintenance', 12286.89, 'RSD', '2026-03-15', '2026-04-28',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '8e767a9f-b99d-5dab-9945-804440f07e6a', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Electricity', 3000.0, 'RSD', '2026-03-15', '2026-04-28',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'b7cab38b-1a12-5ae6-8b73-2baca014338b', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Infostan', 8635.36, 'RSD', '2026-03-15', '2026-04-28',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '043e1872-2189-557b-9feb-1d298f262704', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Parking', 1601.0, 'RSD', '2026-03-15', '2026-04-28',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'f5f8e159-b34f-5910-8def-4b02d0adb70c', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Building Maintenance', 12284.22, 'RSD', '2026-04-15', '2026-05-29',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '4c727899-1bc6-53ac-af3b-9187ee775626', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Electricity', 3000.0, 'RSD', '2026-04-15', '2026-05-29',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'e287c21d-4094-5157-ab6b-89fd5da8aa91', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Infostan', 8161.75, 'RSD', '2026-04-15', '2026-05-29',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '86d8f5dc-5716-5fe2-bbe7-bae60c2969bd', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Parking', 1349.98, 'RSD', '2026-04-15', '2026-05-29',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '4f9b3956-41e7-517d-8041-aaed9e8b4ed9', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Building Maintenance', 12286.4, 'RSD', '2026-05-15', '2026-06-29',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '91ab8d48-98ff-5de0-8cc6-5715c5179091', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Electricity', 3000.0, 'RSD', '2026-05-15', '2026-06-29',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '733e7700-6e22-51f4-a0b0-179a9679f0a9', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Infostan', 10657.9, 'RSD', '2026-05-15', '2026-06-29',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'dd764eea-acf8-541a-a8c6-c8f7fcd0026e', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Parking', 1376.56, 'RSD', '2026-05-15', '2026-06-29',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '7af78d05-57a9-598a-95f1-62953330eae4', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Building Maintenance', 12281.73, 'RSD', '2026-06-15', '2026-08-11',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '9ae1f998-93d1-56dc-ba63-56071a8a1595', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Electricity', 3000.0, 'RSD', '2026-06-15', '2026-08-11',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '692b6177-a15c-5f15-ad06-1855f3413cc6', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Infostan', 4450.15, 'RSD', '2026-06-15', '2026-08-11',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '615f9149-a289-5709-943c-4f723dd8e445', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Parking', 1298.12, 'RSD', '2026-06-15', '2026-08-11',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '4d4c4387-a35d-5830-a4c3-62a33292441e', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Building Maintenance', 12284.34, 'RSD', '2026-07-15', '2026-09-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'e3b9236b-86e3-5b53-9a3c-5e06788f3525', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Electricity', 3000.0, 'RSD', '2026-07-15', '2026-09-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '5c419129-1da1-514f-a6b8-b8f2f9fc6005', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Infostan', 4636.93, 'RSD', '2026-07-15', '2026-09-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '17fdf1e3-ae03-5ba7-a6ce-cda76b56e111', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Parking', 1299.18, 'RSD', '2026-07-15', '2026-09-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '7ffd7c6a-a6c4-5983-8f80-d09ecbec3480', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Building Maintenance', 12280.12, 'RSD', '2026-08-15', '2026-10-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '0275f819-08fa-5d1c-ad6a-62f68e8c8327', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Electricity', 3000.0, 'RSD', '2026-08-15', '2026-10-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '6e77e7e6-6aa8-59f6-af0e-22f0aaf4b12a', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Infostan', 4419.49, 'RSD', '2026-08-15', '2026-10-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'e12081a7-ae3c-5d36-b6be-2d4c0d9c529b', '64ba78b5-a1b9-5157-9070-5481c640b124', '193dbfe1-0b31-5f35-9fe4-e613b5d095ae', 'Parking', 1235.35, 'RSD', '2026-08-15', '2026-10-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '6f3ce80c-05a0-5dfd-920f-fcb588f4a7e1', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Kira', 2450.0, 'EUR', '2026-01-01', '2026-01-09',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '2c20be0e-56d2-5562-8a71-9625d93d3e74', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Kira', 2450.0, 'EUR', '2026-02-01', '2026-02-11',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '027f9088-322a-5e09-a427-331390cf38c6', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Kira', 2450.0, 'EUR', '2026-03-01', '2026-03-06',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '4aec20e3-9ba5-5921-94f8-a7adeebefbd5', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Kira', 2450.0, 'EUR', '2026-04-01', '2026-04-06',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '00ab2724-c94b-5563-a7a5-afba5474554c', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Kira', 2450.0, 'EUR', '2026-05-01', '2026-05-06',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '2e2e8d93-a338-51fb-928c-05dad1afbe50', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Kira', 2450.0, 'EUR', '2026-06-01', '2026-06-05',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'ca566b4c-9289-5bfd-be8d-abeb4b7f6d3d', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Kira', 2450.0, 'EUR', '2026-07-01', '2026-07-08',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '40a3fcfd-2261-5a4c-8f60-d0bc464c4f5c', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Kira', 2450.0, 'EUR', '2026-08-01', '2026-08-07',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '25d195ce-b3b1-506e-b2a8-899cfc148be3', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Kira', 2450.0, 'EUR', '2026-09-01', '2026-09-09',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'd9b4a0e3-f0b0-576c-b677-a361bdac4630', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Kira', 2450.0, 'EUR', '2026-10-01', '2026-10-13',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '41210295-c39c-50c6-a25f-6294dede7881', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Building Maintenance', 28936.76, 'RSD', '2026-01-15', '2026-03-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '59f23cfb-74f6-5cd1-82a3-26ebba47b968', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Electricity', 40860.7, 'RSD', '2026-01-15', '2026-03-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '8db1f0ae-c546-50fb-b95a-5fa1673c4d55', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Infostan', 18541.66, 'RSD', '2026-01-15', '2026-03-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'fe975f04-82c9-503e-a538-21ce6cbde890', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Parking', 1183.24, 'RSD', '2026-01-15', '2026-03-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'fe975f04-82c9-503e-a538-21ce6cbde890', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Parking', 1183.24, 'RSD', '2026-01-15', '2026-03-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'e02a3c7c-90f7-5b3e-8076-e33dcc4fa710', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Building Maintenance', 28932.75, 'RSD', '2026-02-15', '2026-04-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '9c115cf9-920f-5904-b6c0-b5e4270c88ba', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Electricity', 17906.55, 'RSD', '2026-02-15', '2026-04-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd0151637-01a0-5a7e-95bb-354823861692', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Infostan', 20031.52, 'RSD', '2026-02-15', '2026-04-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'abd80ca1-b2d5-5c87-a77f-85965da31b5c', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Parking', 1290.15, 'RSD', '2026-02-15', '2026-04-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'abd80ca1-b2d5-5c87-a77f-85965da31b5c', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Parking', 1290.15, 'RSD', '2026-02-15', '2026-04-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '11990b57-0641-5489-a7be-1cf38fefeee2', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Building Maintenance', 28937.62, 'RSD', '2026-03-15', '2026-05-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '6a5b3457-4d4b-53e7-a22a-070547b8746e', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Electricity', 16103.97, 'RSD', '2026-03-15', '2026-05-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '74ff4b35-68ee-5679-bfaa-8edfb31bee69', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Infostan', 21617.22, 'RSD', '2026-03-15', '2026-05-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'c2c4dc8f-f9a9-57b5-a52b-1c73a4f87adb', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Parking', 1601.0, 'RSD', '2026-03-15', '2026-05-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'c2c4dc8f-f9a9-57b5-a52b-1c73a4f87adb', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Parking', 1601.0, 'RSD', '2026-03-15', '2026-05-06',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '5723d105-b048-522b-8a56-29b9c6f61721', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Building Maintenance', 28931.33, 'RSD', '2026-04-15', '2026-06-05',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '96e69c3f-8068-5a49-987b-b63e0f2bc36e', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Electricity', 11727.2, 'RSD', '2026-04-15', '2026-06-05',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '3b16ff2a-8c66-548a-af8e-613bd966f92f', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Infostan', 18545.21, 'RSD', '2026-04-15', '2026-06-05',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '6ebfcae6-ed17-5f20-8518-de77e134f59f', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Parking', 1349.98, 'RSD', '2026-04-15', '2026-06-05',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '6ebfcae6-ed17-5f20-8518-de77e134f59f', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Parking', 1349.98, 'RSD', '2026-04-15', '2026-06-05',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '18311d20-ee5f-5c8d-804e-8bff4cb53fe4', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Building Maintenance', 28936.46, 'RSD', '2026-05-15', '2026-07-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '8161cf07-3d02-5741-953f-97750ca13c77', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Electricity', 10152.6, 'RSD', '2026-05-15', '2026-07-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '92fc4e62-204c-5110-a7f7-f445ead69467', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Infostan', 22114.36, 'RSD', '2026-05-15', '2026-07-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '248f77b5-c215-57ef-949f-5d09c742a3eb', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Parking', 1376.56, 'RSD', '2026-05-15', '2026-07-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '248f77b5-c215-57ef-949f-5d09c742a3eb', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Parking', 1376.56, 'RSD', '2026-05-15', '2026-07-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '77310cad-bf65-5233-95a4-deab7d858b69', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Building Maintenance', 28925.46, 'RSD', '2026-06-15', '2026-08-07',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '6d1c967d-5446-591d-adde-927767f241db', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Electricity', 12611.13, 'RSD', '2026-06-15', '2026-08-07',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '30165421-f3df-5e91-9d9e-64798ad77a09', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Infostan', 9378.22, 'RSD', '2026-06-15', '2026-08-07',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '38e6369d-6a2f-5514-bb02-63733506eec4', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Parking', 1298.12, 'RSD', '2026-06-15', '2026-08-07',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '38e6369d-6a2f-5514-bb02-63733506eec4', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Parking', 1298.12, 'RSD', '2026-06-15', '2026-08-07',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '3fb95701-53cc-5c53-a0c9-25ce5325b9f2', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Building Maintenance', 28931.59, 'RSD', '2026-07-15', '2026-09-09',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '3ed15d8c-b4e0-5262-92e0-0e762de7ff96', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Electricity', 13972.3, 'RSD', '2026-07-15', '2026-09-09',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '17ac1220-174e-529f-8c2f-e0e01fa726da', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Infostan', 9731.18, 'RSD', '2026-07-15', '2026-09-09',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '3d5f8550-db2a-5081-8363-c8785cd9de65', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Parking', 1299.18, 'RSD', '2026-07-15', '2026-09-09',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '3d5f8550-db2a-5081-8363-c8785cd9de65', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Parking', 1299.18, 'RSD', '2026-07-15', '2026-09-09',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '31a0733e-0c30-52e1-844a-eb4e096cacaa', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Building Maintenance', 28921.65, 'RSD', '2026-08-15', '2026-10-13',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '3381468f-fc66-5f3e-a4c8-7c214c2e8701', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Electricity', 14792.91, 'RSD', '2026-08-15', '2026-10-13',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '3bde31a6-0d1a-5eae-ac87-fd70eb7fc765', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Infostan', 9423.66, 'RSD', '2026-08-15', '2026-10-13',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '95992f29-3890-5409-bba4-d77dc7ddbc90', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Parking', 1235.35, 'RSD', '2026-08-15', '2026-10-13',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '95992f29-3890-5409-bba4-d77dc7ddbc90', '7373b84d-7d76-5e65-8fe8-5d4b9bd0ae2a', '9ddd49b5-22d2-5e6f-b390-a2ca61c2a342', 'Parking', 1235.35, 'RSD', '2026-08-15', '2026-10-13',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '6721893c-2b3f-5eaf-80bc-8f8bc46c0ae6', 'cbb8caa3-60d2-5462-b18d-deb10d72e925', '1bdae1ee-7fb8-55c9-8843-fabb14d70478', 'Kira', 4500.0, 'EUR', '2026-01-01', '2026-01-12',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'a5bcb102-7859-591b-9e07-87e4f7541e25', 'cbb8caa3-60d2-5462-b18d-deb10d72e925', '1bdae1ee-7fb8-55c9-8843-fabb14d70478', 'Kira', 4500.0, 'EUR', '2026-02-01', '2026-02-15',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'fc195f55-b647-5923-b52a-5335628c03f9', 'cbb8caa3-60d2-5462-b18d-deb10d72e925', '1bdae1ee-7fb8-55c9-8843-fabb14d70478', 'Kira', 4500.0, 'EUR', '2026-03-01', '2026-03-16',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '43fe39e6-97b7-5117-a54e-f822ea7b7ebf', 'cbb8caa3-60d2-5462-b18d-deb10d72e925', '1bdae1ee-7fb8-55c9-8843-fabb14d70478', 'Kira', 4500.0, 'EUR', '2026-04-01', '2026-04-09',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '6f95b9ef-6493-5157-935a-578a02dbccc3', 'cbb8caa3-60d2-5462-b18d-deb10d72e925', '1bdae1ee-7fb8-55c9-8843-fabb14d70478', 'Kira', 4500.0, 'EUR', '2026-05-01', '2026-05-06',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '1387b87f-6029-5eec-9f13-316620138de8', 'cbb8caa3-60d2-5462-b18d-deb10d72e925', '1bdae1ee-7fb8-55c9-8843-fabb14d70478', 'Kira', 4500.0, 'EUR', '2026-06-01', '2026-06-05',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'c74c3741-9174-52e4-900a-88be508be635', 'cbb8caa3-60d2-5462-b18d-deb10d72e925', '1bdae1ee-7fb8-55c9-8843-fabb14d70478', 'Kira', 4500.0, 'EUR', '2026-07-01', '2026-07-06',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '91d01ad6-a403-5381-b7bf-a90845f55e8e', 'cbb8caa3-60d2-5462-b18d-deb10d72e925', '1bdae1ee-7fb8-55c9-8843-fabb14d70478', 'Kira', 3900.0, 'EUR', '2026-10-01', '2026-10-02',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '346c1b05-4085-5d6a-a45d-04b3e8542dba', 'cbb8caa3-60d2-5462-b18d-deb10d72e925', '1bdae1ee-7fb8-55c9-8843-fabb14d70478', 'Electricity', 70381.99, 'RSD', '2026-07-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '346c1b05-4085-5d6a-a45d-04b3e8542dba', 'cbb8caa3-60d2-5462-b18d-deb10d72e925', '1bdae1ee-7fb8-55c9-8843-fabb14d70478', 'Electricity', 25694.15, 'RSD', '2026-07-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '3a6b5ee6-b803-5aaa-b84c-aa6b9e616977', 'cbb8caa3-60d2-5462-b18d-deb10d72e925', '1bdae1ee-7fb8-55c9-8843-fabb14d70478', 'Infostan', 1773.73, 'RSD', '2026-07-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '3ebbd177-4087-5a80-bf53-1f940d798345', 'cbb8caa3-60d2-5462-b18d-deb10d72e925', '1bdae1ee-7fb8-55c9-8843-fabb14d70478', 'Infostan', 1841.65, 'RSD', '2026-08-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'c5f3faa6-a020-5b75-8ea8-5ce5641efe49', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Kira', 4000.0, 'EUR', '2026-01-01', '2026-01-11',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'a41d6be1-59e7-5ef3-8e22-d37f9d774d9a', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Kira', 4000.0, 'EUR', '2026-02-01', '2026-01-11',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'c64c49a6-50a9-5096-a457-fde67e90ca39', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Kira', 4000.0, 'EUR', '2026-03-01', '2026-01-11',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '984bb2b4-bb39-5479-90e8-920578056799', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Kira', 4000.0, 'EUR', '2026-04-01', '2026-04-06',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '72364c7c-77a1-5b42-9a77-6991665b34f6', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Kira', 4000.0, 'EUR', '2026-05-01', '2026-04-06',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '8568b7a1-8135-51c8-a3ea-f193a460497f', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Kira', 4000.0, 'EUR', '2026-06-01', '2026-04-06',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'f15ac1aa-57ac-5561-b5a6-9b1e79eb1d4e', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Building Maintenance', 26028.38, 'RSD', '2026-01-15', '2026-02-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '020253cb-5923-59cf-941c-e6d9030a70c2', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Electricity', 4843.22, 'RSD', '2026-01-15', '2026-02-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'b11be9eb-8ab6-5a3e-b9aa-76737c198324', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Infostan', 34326.88, 'RSD', '2026-01-15', '2026-02-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '4e79cf71-ec17-58ca-85aa-d4d2d09f77f7', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Parking', 1871.68, 'RSD', '2026-01-15', '2026-02-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '4e79cf71-ec17-58ca-85aa-d4d2d09f77f7', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Parking', 1280.62, 'RSD', '2026-01-15', '2026-02-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '13a34a0c-2dcd-5664-a381-c9b60a251e40', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Internet/TV', 2900.5, 'RSD', '2026-01-15', '2026-02-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '28355b68-0a3e-5610-a83d-dbf9bced7e75', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Building Maintenance', 42746.86, 'RSD', '2026-02-15', '2026-03-19',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '27a2813d-3b55-5863-b309-e17874ae661f', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Electricity', 8356.13, 'RSD', '2026-02-15', '2026-03-19',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '19e6f200-1586-586f-83b6-4845b0506f1e', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Infostan', 31820.7, 'RSD', '2026-02-15', '2026-03-19',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'e2332775-56d8-546d-8f8f-c0e133268619', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Parking', 1328.95, 'RSD', '2026-02-15', '2026-03-19',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'e2332775-56d8-546d-8f8f-c0e133268619', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Parking', 1942.33, 'RSD', '2026-02-15', '2026-03-19',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '1fff5b64-205b-5bb2-b1b8-f2ed8d305d41', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Internet/TV', 4103.81, 'RSD', '2026-02-15', '2026-03-19',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '3d43e41d-8a2f-5e49-8b9a-1f0803d28680', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Building Maintenance', 42760.71, 'RSD', '2026-03-15', '2026-04-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'fc947548-d1eb-5da1-bfce-05a20a311e6a', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Infostan', 32519.91, 'RSD', '2026-03-15', '2026-04-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'fb11e809-52d1-5d65-b409-9df225320248', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Parking', 1477.69, 'RSD', '2026-03-15', '2026-04-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'fb11e809-52d1-5d65-b409-9df225320248', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Parking', 2159.71, 'RSD', '2026-03-15', '2026-04-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '28ea5827-8d48-5c1d-bb23-4ddb12a55c33', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Internet/TV', 10498.0, 'RSD', '2026-03-15', '2026-04-20',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd4cd9cef-5bc2-5bff-95f2-ceb0f8d24fdf', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Building Maintenance', 42752.08, 'RSD', '2026-04-15', '2026-05-21',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '6d2c8334-7177-572e-a77a-16170aec0b59', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Electricity', 9108.24, 'RSD', '2026-04-15', '2026-05-21',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '7602a758-c036-5d77-9c39-e2d632cf98a6', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Infostan', 28617.97, 'RSD', '2026-04-15', '2026-05-21',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'af3ff270-2037-5b8d-8f94-3d47b8f84e5a', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Parking', 1332.21, 'RSD', '2026-04-15', '2026-05-21',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'af3ff270-2037-5b8d-8f94-3d47b8f84e5a', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Parking', 1947.08, 'RSD', '2026-04-15', '2026-05-21',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'fd384cec-ada9-5312-a8ea-276c429a979f', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Internet/TV', 11668.0, 'RSD', '2026-04-15', '2026-05-21',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '15e0e65a-d836-5ae0-af52-4706b20b170b', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Building Maintenance', 42753.77, 'RSD', '2026-05-15', '2026-06-26',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'a450e1fe-d2f2-5d20-bab3-262e47bf83d2', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Electricity', 6240.72, 'RSD', '2026-05-15', '2026-06-26',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'cead7487-3d9e-5964-becb-97dbe4a8b0f1', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Infostan', 24258.03, 'RSD', '2026-05-15', '2026-06-26',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '5489aa2a-093e-522c-8b67-c49e4442420c', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Parking', 1381.21, 'RSD', '2026-05-15', '2026-06-26',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '5489aa2a-093e-522c-8b67-c49e4442420c', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Parking', 2018.71, 'RSD', '2026-05-15', '2026-06-26',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd344c6fb-c1c7-549e-b1db-0b6ebe6e0531', 'cf8cbb12-af9f-5093-bda5-6dae9f95b131', 'e3fe8a13-a665-514b-b55e-a65a58dbca48', 'Internet/TV', 12056.08, 'RSD', '2026-05-15', '2026-06-26',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'e1cc77de-ac69-52ca-bc91-c7a4a123fcb5', '500002db-410a-5fc6-b10f-1cdd119ed20a', 'e559b478-f5e8-5117-8bc3-828316fda97d', 'Kira', 910.0, 'EUR', '2026-06-01', '2026-06-08',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '37a90a78-5996-52c1-a29c-7d4a21cac0c7', '500002db-410a-5fc6-b10f-1cdd119ed20a', 'e559b478-f5e8-5117-8bc3-828316fda97d', 'Kira', 1300.0, 'EUR', '2026-07-01', '2026-07-06',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '36198640-b7b9-5d8b-81cd-76e762eac498', '500002db-410a-5fc6-b10f-1cdd119ed20a', 'e559b478-f5e8-5117-8bc3-828316fda97d', 'Kira', 1300.0, 'EUR', '2026-08-01', '2026-08-05',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '1233babb-10f3-5d3b-818b-9befb5328707', '500002db-410a-5fc6-b10f-1cdd119ed20a', 'e559b478-f5e8-5117-8bc3-828316fda97d', 'Kira', 1300.0, 'EUR', '2026-09-01', '2026-09-08',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '20855bfd-2cf9-5d58-a874-3e68ec090660', '500002db-410a-5fc6-b10f-1cdd119ed20a', 'e559b478-f5e8-5117-8bc3-828316fda97d', 'Kira', 1300.0, 'EUR', '2026-10-01', '2026-10-07',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'df30ce2b-6c56-52fd-934b-eb658469cad3', '500002db-410a-5fc6-b10f-1cdd119ed20a', 'e559b478-f5e8-5117-8bc3-828316fda97d', 'Electricity', 5697.23, 'RSD', '2026-06-15', '2026-08-05',
        'paid', 'Oransal kısmi ödeme (5697.23 RSD ödendi)', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '4feba9cb-65fb-51c3-a505-58e0bf5f96dd', '500002db-410a-5fc6-b10f-1cdd119ed20a', 'e559b478-f5e8-5117-8bc3-828316fda97d', 'Electricity (Kalan)', 2684.46, 'RSD', '2026-06-15', NULL,
        'pending', 'Kalan borç bakiyesi (2684.46 RSD)', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '8ea9213b-f878-5a5e-a37a-27546a4f95f9', '500002db-410a-5fc6-b10f-1cdd119ed20a', 'e559b478-f5e8-5117-8bc3-828316fda97d', 'Infostan', 2123.19, 'RSD', '2026-06-15', '2026-08-05',
        'paid', 'Oransal kısmi ödeme (2123.19 RSD ödendi)', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '22c260fa-d89b-596a-bee7-e94a878457ba', '500002db-410a-5fc6-b10f-1cdd119ed20a', 'e559b478-f5e8-5117-8bc3-828316fda97d', 'Infostan (Kalan)', 1000.42, 'RSD', '2026-06-15', NULL,
        'pending', 'Kalan borç bakiyesi (1000.42 RSD)', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '37ba4445-4698-54af-9121-bf7fbf156964', '500002db-410a-5fc6-b10f-1cdd119ed20a', 'e559b478-f5e8-5117-8bc3-828316fda97d', 'Building Maintenance', 1518.44, 'RSD', '2026-06-15', '2026-08-05',
        'paid', 'Oransal kısmi ödeme (1518.44 RSD ödendi)', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'b916c0d7-bb34-5a12-96f5-51e3bfbbb5e9', '500002db-410a-5fc6-b10f-1cdd119ed20a', 'e559b478-f5e8-5117-8bc3-828316fda97d', 'Building Maintenance (Kalan)', 715.47, 'RSD', '2026-06-15', NULL,
        'pending', 'Kalan borç bakiyesi (715.47 RSD)', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'c00db048-7a6a-5479-945e-ca7d7b1109ff', '500002db-410a-5fc6-b10f-1cdd119ed20a', 'e559b478-f5e8-5117-8bc3-828316fda97d', 'Internet/TV', 4110.97, 'RSD', '2026-06-15', '2026-08-05',
        'paid', 'Oransal kısmi ödeme (4110.97 RSD ödendi)', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '6802bdbd-6e67-531d-adde-dfb1ea21c52a', '500002db-410a-5fc6-b10f-1cdd119ed20a', 'e559b478-f5e8-5117-8bc3-828316fda97d', 'Internet/TV (Kalan)', 1937.03, 'RSD', '2026-06-15', NULL,
        'pending', 'Kalan borç bakiyesi (1937.03 RSD)', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '7eee31f7-9c76-562d-855a-638a176b0722', '500002db-410a-5fc6-b10f-1cdd119ed20a', 'e559b478-f5e8-5117-8bc3-828316fda97d', 'Electricity', 6230.42, 'RSD', '2026-07-15', '2026-09-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'eb578be8-d8b7-543b-8d7b-902854a8b716', '500002db-410a-5fc6-b10f-1cdd119ed20a', 'e559b478-f5e8-5117-8bc3-828316fda97d', 'Infostan', 3091.54, 'RSD', '2026-07-15', '2026-09-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd3d18f0c-0416-5834-8717-4425e35ba8fa', '500002db-410a-5fc6-b10f-1cdd119ed20a', 'e559b478-f5e8-5117-8bc3-828316fda97d', 'Building Maintenance', 2234.04, 'RSD', '2026-07-15', '2026-09-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'ed0fa140-3d12-5470-9035-342cd405b0ad', '500002db-410a-5fc6-b10f-1cdd119ed20a', 'e559b478-f5e8-5117-8bc3-828316fda97d', 'Internet/TV', 6391.27, 'RSD', '2026-07-15', '2026-09-08',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'b95890e7-47b5-5bc2-9ca5-dcb55a8b2e98', '500002db-410a-5fc6-b10f-1cdd119ed20a', 'e559b478-f5e8-5117-8bc3-828316fda97d', 'Electricity', 5501.3, 'RSD', '2026-08-15', '2026-10-07',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'bac54392-983b-5215-9dd3-f19774140e7b', '500002db-410a-5fc6-b10f-1cdd119ed20a', 'e559b478-f5e8-5117-8bc3-828316fda97d', 'Infostan', 3067.89, 'RSD', '2026-08-15', '2026-10-07',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'a8d7b46a-9d38-51e2-8a9c-d4045663647a', '500002db-410a-5fc6-b10f-1cdd119ed20a', 'e559b478-f5e8-5117-8bc3-828316fda97d', 'Building Maintenance', 2233.84, 'RSD', '2026-08-15', '2026-10-07',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'e0b12fa3-c783-5d1e-9e27-00e8e845424e', '500002db-410a-5fc6-b10f-1cdd119ed20a', 'e559b478-f5e8-5117-8bc3-828316fda97d', 'Internet/TV', 6048.0, 'RSD', '2026-08-15', '2026-10-07',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'e2d307aa-81f8-5d1f-a39f-3155c9cf0db5', '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'bb6671cf-bf7d-5a27-a63f-479e9d6ae41d', 'Kira', 1695.0, 'EUR', '2026-05-01', '2026-06-10',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'eef65b99-0bac-53e5-a98c-7854c91ebaed', '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'bb6671cf-bf7d-5a27-a63f-479e9d6ae41d', 'Kira', 2500.0, 'EUR', '2026-06-01', '2026-05-10',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'b52516ba-fe0d-500f-8dd6-2f7867ee7f62', '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'bb6671cf-bf7d-5a27-a63f-479e9d6ae41d', 'Kira', 2500.0, 'EUR', '2026-07-01', '2026-07-01',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'aa3331a0-c469-53ce-89ac-ffe53d008228', '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'bb6671cf-bf7d-5a27-a63f-479e9d6ae41d', 'Kira', 2500.0, 'EUR', '2026-08-01', '2026-08-03',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '6d594c52-e0dd-5b30-a6ab-6a82297c8841', '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'bb6671cf-bf7d-5a27-a63f-479e9d6ae41d', 'Kira', 2500.0, 'EUR', '2026-09-01', '2026-09-02',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '427cd19c-1a7a-5962-bbae-7086644e0d6d', '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'bb6671cf-bf7d-5a27-a63f-479e9d6ae41d', 'Kira', 2500.0, 'EUR', '2026-10-01', '2026-10-13',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'd6d28157-3fe2-5573-85d2-48f294d91496', '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'bb6671cf-bf7d-5a27-a63f-479e9d6ae41d', 'Building Maintenance', 20073.13, 'RSD', '2026-05-15', '2026-07-01',
        'paid', 'Oransal kısmi ödeme (20073.13 RSD ödendi)', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '3b061fe6-66e8-5b9a-84ba-4b69247a8c80', '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'bb6671cf-bf7d-5a27-a63f-479e9d6ae41d', 'Building Maintenance (Kalan)', 9706.8, 'RSD', '2026-05-15', NULL,
        'pending', 'Kalan borç bakiyesi (9706.80 RSD)', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '6a9a9541-ace8-5365-929e-f4a986bfe068', '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'bb6671cf-bf7d-5a27-a63f-479e9d6ae41d', 'Electricity', 6152.01, 'RSD', '2026-05-15', '2026-07-01',
        'paid', 'Oransal kısmi ödeme (6152.01 RSD ödendi)', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'f6e7540c-b3ad-5ba0-acfa-3ce61f0ce87c', '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'bb6671cf-bf7d-5a27-a63f-479e9d6ae41d', 'Electricity (Kalan)', 2974.94, 'RSD', '2026-05-15', NULL,
        'pending', 'Kalan borç bakiyesi (2974.94 RSD)', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '3d5b1b78-8e72-5220-896b-9c790c4c2d5c', '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'bb6671cf-bf7d-5a27-a63f-479e9d6ae41d', 'Infostan', 8762.63, 'RSD', '2026-05-15', '2026-07-01',
        'paid', 'Oransal kısmi ödeme (8762.63 RSD ödendi)', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '4cc5aa18-83b2-551b-9804-df91b8f3be2f', '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'bb6671cf-bf7d-5a27-a63f-479e9d6ae41d', 'Infostan (Kalan)', 4237.37, 'RSD', '2026-05-15', NULL,
        'pending', 'Kalan borç bakiyesi (4237.37 RSD)', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'c6d1e9fa-30ae-57c3-8fc0-7491d8021d86', '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'bb6671cf-bf7d-5a27-a63f-479e9d6ae41d', 'Internet/TV', 3612.23, 'RSD', '2026-05-15', '2026-07-01',
        'paid', 'Oransal kısmi ödeme (3612.23 RSD ödendi)', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'a323730d-858b-5535-ac10-1df95bf30e1b', '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'bb6671cf-bf7d-5a27-a63f-479e9d6ae41d', 'Internet/TV (Kalan)', 1746.77, 'RSD', '2026-05-15', NULL,
        'pending', 'Kalan borç bakiyesi (1746.77 RSD)', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '1f4a7e0c-a703-51b5-9431-24817f94497d', '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'bb6671cf-bf7d-5a27-a63f-479e9d6ae41d', 'Building Maintenance', 29749.54, 'RSD', '2026-06-15', '2026-08-03',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'e2ca4635-611b-5266-86d1-ddd7f37d53c9', '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'bb6671cf-bf7d-5a27-a63f-479e9d6ae41d', 'Electricity', 12472.42, 'RSD', '2026-06-15', '2026-08-03',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'c07f2cd7-ee1a-504c-9d5c-5aa78b3839a1', '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'bb6671cf-bf7d-5a27-a63f-479e9d6ae41d', 'Infostan', 12145.51, 'RSD', '2026-06-15', '2026-08-03',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '34033a81-62a7-5407-991c-4c956d9e6359', '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'bb6671cf-bf7d-5a27-a63f-479e9d6ae41d', 'Internet/TV', 5359.0, 'RSD', '2026-06-15', '2026-08-03',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'aae8784c-28f9-56b2-8686-d33511624340', '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'bb6671cf-bf7d-5a27-a63f-479e9d6ae41d', 'Building Maintenance', 29757.57, 'RSD', '2026-07-15', '2026-09-02',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        'f52ef04a-c02a-5694-8f99-80d1f7ed67bf', '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'bb6671cf-bf7d-5a27-a63f-479e9d6ae41d', 'Electricity', 11722.78, 'RSD', '2026-07-15', '2026-09-02',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '99905360-b498-5fbc-9af7-dd268f236721', '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'bb6671cf-bf7d-5a27-a63f-479e9d6ae41d', 'Infostan', 11655.12, 'RSD', '2026-07-15', '2026-09-02',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '31950ef2-7e2b-57d6-9eaa-f150ed3d286d', '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'bb6671cf-bf7d-5a27-a63f-479e9d6ae41d', 'Internet/TV', 5659.0, 'RSD', '2026-07-15', '2026-09-02',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '03525f31-4845-5b80-bc99-656e92c99406', '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'bb6671cf-bf7d-5a27-a63f-479e9d6ae41d', 'Building Maintenance', 29742.91, 'RSD', '2026-08-15', '2026-10-13',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '58840e50-19d0-583d-b584-1246e0654abd', '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'bb6671cf-bf7d-5a27-a63f-479e9d6ae41d', 'Electricity', 12999.65, 'RSD', '2026-08-15', '2026-10-13',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '4db8be48-f897-5df0-be0b-8adb1f67edab', '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'bb6671cf-bf7d-5a27-a63f-479e9d6ae41d', 'Infostan', 11600.03, 'RSD', '2026-08-15', '2026-10-13',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '68401fa0-1caa-5634-959d-11232d9081af', '6bbc29eb-4ba6-5289-92ad-fec71fb090b6', 'bb6671cf-bf7d-5a27-a63f-479e9d6ae41d', 'Internet/TV', 5659.0, 'RSD', '2026-08-15', '2026-10-13',
        'paid', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '2c62afc6-aaa7-55a2-89fb-30aba2c1e840', '964b18b7-4c64-54a1-b9ee-35f5ad7df0ba', 'a253202e-e51d-5f05-b845-45ff2e5cd287', 'Kira', 2800.0, 'EUR', '2026-08-01', '2026-07-28',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '1c0ad4a8-a8b8-5f29-94f5-d3821aead2bc', '964b18b7-4c64-54a1-b9ee-35f5ad7df0ba', 'a253202e-e51d-5f05-b845-45ff2e5cd287', 'Kira', 2800.0, 'EUR', '2026-09-01', '2026-09-01',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '7c303802-dd00-51bb-a60e-7ed5a8ba3076', '964b18b7-4c64-54a1-b9ee-35f5ad7df0ba', 'a253202e-e51d-5f05-b845-45ff2e5cd287', 'Kira', 2800.0, 'EUR', '2026-10-01', '2026-09-01',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '6bb89d88-0ba0-54ba-898f-1de184e21457', 'd97b99c6-9b85-56ba-82fd-d4349b846268', 'caceed58-63e6-5b4b-a006-e9b4fb669843', 'Kira', 2270.0, 'EUR', '2026-08-01', '2026-08-11',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'e8cfdbec-4cde-5f72-af0d-d68dd7ed8307', 'd97b99c6-9b85-56ba-82fd-d4349b846268', 'caceed58-63e6-5b4b-a006-e9b4fb669843', 'Kira', 3500.0, 'EUR', '2026-09-01', '2026-09-01',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '9fc22f19-cbf9-5dc4-b457-c8660549a28d', 'd97b99c6-9b85-56ba-82fd-d4349b846268', 'caceed58-63e6-5b4b-a006-e9b4fb669843', 'Kira', 3350.0, 'EUR', '2026-10-01', '2026-10-01',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '0ea170f1-93dc-5df4-94d5-ec125923ab04', '6c87c83b-3315-5079-8fa3-96b2cf34b920', '8a58ee7b-386f-56b6-8093-cab23000052b', 'Kira', 4000.0, 'EUR', '2026-08-01', '2026-08-04',
        'paid', 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '052fbe8d-bb13-53c9-830d-14f16c3c430e', '6c87c83b-3315-5079-8fa3-96b2cf34b920', '8a58ee7b-386f-56b6-8093-cab23000052b', 'Kira', 4000.0, 'EUR', '2026-09-01', '2026-08-04',
        'paid', 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'dfd53d6d-64b8-5f5d-8818-87fc110754c8', '6c87c83b-3315-5079-8fa3-96b2cf34b920', '8a58ee7b-386f-56b6-8093-cab23000052b', 'Kira', 4000.0, 'EUR', '2026-10-01', '2026-08-04',
        'paid', 'bank_transfer', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '9c3e1367-43fd-512a-9267-ed5017da4686', '9c88e542-8da5-5fe4-a661-111e2e059b1a', 'b076d82d-0722-56ba-8da6-f2dbd11ff775', 'Kira', 3900.0, 'EUR', '2026-08-01', '2026-08-01',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '15051c82-ab4e-5d07-9e30-d4c1d35552d4', '9c88e542-8da5-5fe4-a661-111e2e059b1a', 'b076d82d-0722-56ba-8da6-f2dbd11ff775', 'Kira', 3900.0, 'EUR', '2026-09-01', '2026-09-01',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '6aaed2a4-a076-5100-9a55-7f0ecd5ef881', '9c88e542-8da5-5fe4-a661-111e2e059b1a', 'b076d82d-0722-56ba-8da6-f2dbd11ff775', 'Kira', 3900.0, 'EUR', '2026-10-01', '2026-10-01',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '20181d65-99e4-5e39-806e-23a1dc7c7610', '2e42fd7e-21e3-56d5-ad1c-4a3b7b76147b', '22302dc8-29d4-5bb1-8f69-63269e5ebede', 'Kira', 1785.0, 'EUR', '2026-09-01', '2026-09-15',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '0d7d70f2-755f-515c-9fac-0f44a25ce7a2', '2e42fd7e-21e3-56d5-ad1c-4a3b7b76147b', '22302dc8-29d4-5bb1-8f69-63269e5ebede', 'Kira', 3350.0, 'EUR', '2026-10-01', '2026-09-15',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, owner_note, payment_method, receiver_type, created_at
    ) VALUES (
        '1d33787d-17bb-5809-ac7a-6b96cbe80784', '56504287-7bba-5606-b530-62ee89ebd950', NULL, 'Building Maintenance', 5000.0, 'RSD', '2026-01-15', NULL,
        'pending', NULL, 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status,
        owner_note = EXCLUDED.owner_note;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '7bccfda5-825f-55bd-a9f4-0ec697d3654a', '500755dd-4e28-51cd-afed-2085781fd68f', '5e70a56e-88ab-5268-912d-b71eb7391f8a', 'Kira', 5000.0, 'EUR', '2026-09-01', '2026-08-27',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'd87e5c79-cd77-5882-acc5-f2efed5ae568', '500755dd-4e28-51cd-afed-2085781fd68f', '5e70a56e-88ab-5268-912d-b71eb7391f8a', 'Kira', 5000.0, 'EUR', '2026-10-01', '2026-10-02',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'fa6e4d59-9246-5290-a7ed-5c14cb1cc139', '85f588d5-a1c2-566a-b756-c4ce698dbca6', '7c388da3-1229-58ad-9a2f-7769fc4c8e14', 'Kira', 2470.0, 'EUR', '2026-08-01', '2026-08-10',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '0f77eaf1-9abe-575b-954d-3bf3eed4fae8', '85f588d5-a1c2-566a-b756-c4ce698dbca6', '7c388da3-1229-58ad-9a2f-7769fc4c8e14', 'Kira', 4500.0, 'EUR', '2026-09-01', '2026-09-08',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'b5d27a86-eef9-5eac-b19b-c16d883e3c9a', '85f588d5-a1c2-566a-b756-c4ce698dbca6', '7c388da3-1229-58ad-9a2f-7769fc4c8e14', 'Kira', 4500.0, 'EUR', '2026-10-01', '2026-10-07',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '83ba9b19-b451-587c-9253-9b1c7833ea85', 'b34a30ae-b228-5be0-9b59-21d8980ac274', 'c19e4b34-4b7c-5ddf-9aaa-d008e6747421', 'Kira', 3060.0, 'EUR', '2026-08-01', '2026-08-10',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'd81207e6-0de8-5256-be62-79789e914a06', 'b34a30ae-b228-5be0-9b59-21d8980ac274', 'c19e4b34-4b7c-5ddf-9aaa-d008e6747421', 'Kira', 4300.0, 'EUR', '2026-09-01', '2026-09-08',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'f60e3720-7ec1-50d8-a901-74e37ec53fe1', 'b34a30ae-b228-5be0-9b59-21d8980ac274', 'c19e4b34-4b7c-5ddf-9aaa-d008e6747421', 'Kira', 4300.0, 'EUR', '2026-10-01', '2026-10-02',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'c286b736-d771-52eb-a024-4ad364a5cd14', '21a7b98f-23fe-5371-9895-7dfbcfd3e050', '46f4754a-2ed5-534f-8bb8-27b4995f5acf', 'Kira', 4000.0, 'EUR', '2026-08-01', '2026-08-04',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'eb398487-6ad0-57dc-8dc5-d9d9c6d4d56f', '21a7b98f-23fe-5371-9895-7dfbcfd3e050', '46f4754a-2ed5-534f-8bb8-27b4995f5acf', 'Kira', 4450.0, 'EUR', '2026-09-01', '2026-09-09',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        'b9837335-39fa-5cad-a16a-43933a67acb2', '21a7b98f-23fe-5371-9895-7dfbcfd3e050', '46f4754a-2ed5-534f-8bb8-27b4995f5acf', 'Kira', 4450.0, 'EUR', '2026-10-01', '2026-10-02',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '8abb6436-2a8f-5399-aae3-84de0b72af35', 'e87ef13e-8e35-52b6-a84f-2acdf2dd72aa', '260f41dd-99d5-56ab-9945-be3db40881b6', 'Kira', 4500.0, 'EUR', '2026-09-01', '2026-09-08',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '052cd4fd-e4db-55c9-8831-9a4070047657', 'e87ef13e-8e35-52b6-a84f-2acdf2dd72aa', '260f41dd-99d5-56ab-9945-be3db40881b6', 'Kira', 4500.0, 'EUR', '2026-10-01', '2026-10-02',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '867fdbb2-ddd9-5aba-90d9-e9b6a6fdf07c', '12810dde-341d-5567-ad7b-7a4d060fe71f', '4c1baa60-2aeb-5ba0-98e9-80ea06d9ffc5', 'Kira', 2525.0, 'EUR', '2026-08-01', '2026-08-14',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '67aa8a1f-9c2b-5fc0-aced-d20d62465fcc', '12810dde-341d-5567-ad7b-7a4d060fe71f', '4c1baa60-2aeb-5ba0-98e9-80ea06d9ffc5', 'Kira', 4350.0, 'EUR', '2026-09-01', '2026-09-10',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '838d81e0-ec2e-5fb6-81c1-4c4dbab9cd5d', 'd21a40f8-ebd6-5314-b063-f69e818c54d2', 'af3ddb30-90bf-56e9-b8e0-4b4bf155c11b', 'Kira', 4200.0, 'EUR', '2026-10-01', '2026-09-24',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '75e2cd3d-ec54-5b14-99ca-43bc9bdacb34', 'd1945411-5842-52e2-9988-87b3cb9fa0fd', '0f1747e9-30ee-5220-bcd8-1de2fe6905eb', 'Kira', 2100.0, 'EUR', '2026-10-01', '2026-09-15',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '591f14bf-86cd-514c-bf6c-198a27d2d3a6', '2958095f-a25c-58aa-ab38-476cb0f954eb', '2dcd3938-83f0-561c-a7aa-2fa55d9ea465', 'Kira', 1150.0, 'EUR', '2026-09-01', '2026-09-16',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;

    INSERT INTO public.rent_payments (
        id, property_id, contract_id, title, amount, currency, due_date, paid_at,
        status, payment_method, receiver_type, created_at
    ) VALUES (
        '85962c54-0ff2-55f2-ad7a-cac0b9feb118', '2958095f-a25c-58aa-ab38-476cb0f954eb', '2dcd3938-83f0-561c-a7aa-2fa55d9ea465', 'Kira', 2300.0, 'EUR', '2026-10-01', '2026-10-01',
        'paid', 'cash', 'owner', now()
    ) ON CONFLICT (id) DO UPDATE SET
        amount = EXCLUDED.amount,
        paid_at = EXCLUDED.paid_at,
        status = EXCLUDED.status;


    -- Ensure absolutely no rent or utility bills exist before 2026-01-01 for this profile's properties
    DELETE FROM public.rent_payments 
    WHERE due_date < '2026-01-01' 
    AND property_id IN (
        SELECT id FROM public.properties 
        WHERE agency_id = 'e4a8d708-acf2-4816-b59a-677c7656ce7c' OR landlord_id = 'e4a8d708-acf2-4816-b59a-677c7656ce7c'
    );


    COMMIT;
