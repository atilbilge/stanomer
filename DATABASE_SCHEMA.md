# Stanomer Veritabanı Tam Şema Dokümantasyonu (Supabase / PostgreSQL)

Bu doküman, Stanomer uygulamasının kullandığı tüm veritabanı yapısını (Tablolar, Sütunlar, Veri Tipleri, Kısıtlamalar, ENUM'lar, Görünümler, **Tüm Saklı Yordamların / RPC Fonksiyonlarının Tam Kodu**, Tetikleyiciler, Depolama Alanları ve RLS Güvenlik Politikaları) eksiksiz ve detaylı bir şekilde içermektedir.

> **Son Güncelleme: 2026-07-29 — B2B2C Acente (Agency) Desteği eklendi.**

---

## 1. Özel Veri Tipleri (ENUMs)

Veritabanında tanımlı özel ENUM tipleri:

### 1.1 `user_role`
Kullanıcının platformdaki ana rolünü belirler.
* `'landlord'`: Ev Sahibi
* `'tenant'`: Kiracı
* `'both'`: Hem Ev Sahibi hem Kiracı
* `'agency'`: **[YENİ]** Emlak Acentesi — B2B2C modeli için, mülkleri yönetir ve kiracılar ile ev sahipleri arasında aracılık yapar

### 1.2 `contract_status`
Kira sözleşmesinin mevcut durumunu temsil eder.
* `'pending'`: Davet edilmiş / onay bekliyor
* `'negotiating'`: Şartlar üzerinde çift taraflı pazarlık yapılıyor
* `'active'`: Onaylanmış ve yürürlükte
* `'rejected'`: Davet veya sözleşme reddedildi
* `'cancelled'`: Sözleşme iptal edildi
* `'terminated'`: Sözleşme vaktinden önce feshedildi
* `'expired'`: Sözleşme süresi doldu

### 1.3 `rent_payment_status`
Kira veya fatura ödeme kaleminin finansal durumunu gösterir.
* `'pending'`: Ödeme bekleniyor / Vadesi gelmedi veya ödenmedi
* `'declared'`: Kiracı ödemeyi yaptığını beyan etti (Dekont yüklendi/bildirildi)
* `'paid'`: Ev sahibi ödemeyi onayladı veya sistem 5 gün sonra otomatik onayladı
* `'overdue'`: Gecikmiş ödeme
* `'disputed'`: Ödemeye itiraz edildi (Ev sahibi beyanı reddetti)
* `'rejected'`: Ödeme reddedildi

### 1.4 `tax_type`
Sözleşme ve mülkteki vergi sorumluluk türünü temsil eder.
* `'included'`: Vergi kiraya dahildir
* `'excluded_tenant'`: Vergi kiraya dahil değildir (Kiracı öder)
* `'excluded_landlord'`: Vergi kiraya dahil değildir (Ev sahibi öder)

---

## 2. Veritabanı Tabloları (Tables) & RLS Politikaları

### 2.1 `profiles`
Kullanıcıların profil, kimlik ve rol bilgilerini saklar. `auth.users` ile Bire-Bir (1:1) ilişkilidir.

#### Tablo Yapısı
| Sütun Adı | Veri Tipi | Nullable | Varsayılan Değer | Kısıtlamalar & İlişkiler | Açıklama |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `id` | `UUID` | **NO** | - | **PK**, `REFERENCES auth.users(id) ON DELETE CASCADE` | Kullanıcı benzersiz kimliği |
| `email` | `TEXT` | YES | `NULL` | - | Kullanıcı e-posta adresi |
| `full_name` | `TEXT` | YES | `NULL` | - | Ad Soyad |
| `phone_number` | `TEXT` | YES | `NULL` | - | Telefon numarası |
| `avatar_url` | `TEXT` | YES | `NULL` | - | Profil fotoğrafı URL'si |
| `role` | `user_role` | YES | `'landlord'` | - | Kullanıcı ana rolü |
| `active_role` | `TEXT` | YES | `'landlord'` | - | Anlık aktif rol |
| `company_name` | `TEXT` | YES | `NULL` | - | **[YENİ]** Acente şirket adı (beyaz etiket branding) |
| `logo_url` | `TEXT` | YES | `NULL` | - | **[YENİ]** Acente logo URL'si |
| `color_scheme` | `JSONB` | YES | `'{}'::jsonb` | - | **[YENİ]** Acente renk şeması JSON (`primary`, `accent`, `brand_gold`, `bg_white`, `text_primary`, `border`) |
| `created_at` | `TIMESTAMPTZ` | **NO** | `now()` | - | Oluşturulma zamanı |
| `updated_at` | `TIMESTAMPTZ` | **NO** | `now()` | - | Güncellenme zamanı |

#### RLS Politikaları (`public.profiles`)
* **`"Users can insert their own profile"`**: `FOR INSERT TO authenticated WITH CHECK (auth.uid() = id)`
* **`"Users can update their own profile"`**: `FOR UPDATE TO authenticated USING (auth.uid() = id)`
* **`"Authenticated users can see all profiles"`**: `FOR SELECT TO authenticated USING (true)`

---

### 2.2 `properties`
Ev sahiplerinin kaydettiği mülk (konut/daire) verilerini tutar.

#### Tablo Yapısı
| Sütun Adı | Veri Tipi | Nullable | Varsayılan Değer | Kısıtlamalar & İlişkiler | Açıklama |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `id` | `UUID` | **NO** | `gen_random_uuid()` | **PK** | Mülk benzersiz kimliği |
| `landlord_id` | `UUID` | YES | `NULL` | **FK** `REFERENCES profiles(id)` | Ev sahibi kullanıcı ID (acente eklediğinde sahiplik devredilene kadar NULL olabilir) |
| `tenant_id` | `UUID` | YES | `NULL` | **FK** `REFERENCES profiles(id)` | Aktif kiracı kullanıcı ID |
| `agency_id` | `UUID` | YES | `NULL` | **FK** `REFERENCES profiles(id) ON DELETE SET NULL` | **[YENİ]** Mülkü yöneten acente kullanıcı ID |
| `landlord_name` | `TEXT` | YES | `NULL` | - | **[YENİ]** Ev sahibinin adı soyadı (acente girişli) |
| `landlord_phone` | `TEXT` | YES | `NULL` | - | **[YENİ]** Ev sahibinin telefon numarası |
| `landlord_email` | `TEXT` | YES | `NULL` | - | **[YENİ]** Ev sahibinin e-posta adresi |
| `city` | `TEXT` | YES | `NULL` | - | **[YENİ]** Mülkün bulunduğu şehir (ör. İstanbul, Belgrad) |
| `title` | `TEXT` | **NO** | - | - | Mülk adı / başlığı |
| `address` | `TEXT` | **NO** | - | - | Mülk açık adresi |
| `default_monthly_rent` | `NUMERIC` | YES | `NULL` | - | Şablon varsayılan kira tutarı |
| `default_deposit_amount` | `NUMERIC` | YES | `NULL` | - | Şablon varsayılan depozito |
| `currency` | `TEXT` | **NO** | `'EUR'` | - | Para birimi (`EUR`, `RSD`, `USD`, vb.) |
| `default_due_day` | `INTEGER` | YES | `1` | `CHECK (due_day >= 1 AND due_day <= 31)` | Varsayılan aylık son ödeme günü |
| `expenses_template` | `JSONB` | YES | `'[]'::jsonb` | - | Şablon yan gider kalemleri |
| `owner_note` | `TEXT` | YES | `NULL` | - | Ev sahibine özel notlar |
| `tax_type` | `tax_type` | YES | `'included'` | - | Vergi tipi şablonu |
| `created_at` | `TIMESTAMPTZ` | **NO** | `now()` | - | Kayıt tarihi |
| `updated_at` | `TIMESTAMPTZ` | **NO** | `now()` | - | Son güncelleme tarihi |

#### RLS Politikaları (`public.properties`)
* **`landlord_select_properties`**: `FOR SELECT TO authenticated USING (landlord_id = auth.uid())`
* **`tenant_select_properties`**: `FOR SELECT TO authenticated USING (tenant_id = auth.uid())`
* **`tenant_view_invited_properties`**: `FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM invitations i WHERE i.property_id = properties.id AND LOWER(i.invitee_email) = LOWER(auth.jwt()->>'email')))`
* **`landlord_update_properties`**: `FOR UPDATE TO authenticated USING (landlord_id = auth.uid())`
* **`tenant_join_property`**: `FOR UPDATE TO authenticated USING (tenant_id IS NULL) WITH CHECK (tenant_id = auth.uid())`
* **`tenant_leave_property`**: `FOR UPDATE TO authenticated USING (tenant_id = auth.uid()) WITH CHECK (tenant_id IS NULL)`

---

### 2.3 `contracts`
Mülke bağlı ev sahibi ve kiracı arasındaki kira sözleşmelerini tutar.

#### Tablo Yapısı
| Sütun Adı | Veri Tipi | Nullable | Varsayılan Değer | Kısıtlamalar & İlişkiler | Açıklama |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `id` | `UUID` | **NO** | `gen_random_uuid()` | **PK** | Sözleşme ID |
| `property_id` | `UUID` | **NO** | - | **FK** `REFERENCES properties(id) ON DELETE CASCADE` | İlgili mülk ID |
| `landlord_id` | `UUID` | **NO** | - | **FK** `REFERENCES profiles(id)` | Ev sahibi ID |
| `tenant_id` | `UUID` | YES | `NULL` | **FK** `REFERENCES profiles(id)` | Kiracı ID |
| `agency_id` | `UUID` | YES | `NULL` | **FK** `REFERENCES profiles(id) ON DELETE SET NULL` | **[YENİ]** Sözleşmeyi yöneten acente ID |
| `invitee_email` | `TEXT` | YES | `NULL` | - | Davet edilen kiracı e-postası |
| `inviter_name` | `TEXT` | YES | `NULL` | - | Davet eden ev sahibi/acente adı |
| `token` | `TEXT` | YES | `NULL` | - | Davet/Sözleşme erişim tokeni |
| `deposit_currency` | `TEXT` | YES | `'EUR'` | - | Depozito para birimi |
| `tenant_feedback` | `TEXT` | YES | `NULL` | - | Kiracı geri bildirimi / revizyon notu |
| `status` | `contract_status` | **NO** | `'pending'` | - | Sözleşme durumu |
| `monthly_rent` | `NUMERIC` | **NO** | - | - | Aylık kira tutarı |
| `deposit_amount` | `NUMERIC` | YES | `0` | - | Depozito tutarı |
| `currency` | `TEXT` | **NO** | `'EUR'` | - | Para birimi |
| `due_day` | `INTEGER` | **NO** | `1` | `CHECK (due_day >= 1 AND due_day <= 31)` | Aylık son ödeme günü |
| `start_date` | `DATE` | **NO** | - | - | Başlangıç tarihi |
| `end_date` | `DATE` | **NO** | - | - | Bitiş tarihi |
| `expenses_config` | `JSONB` | YES | `'[]'::jsonb` | - | Sözleşmeye bağlı ödeme ve gider dağılımları |
| `contract_url` | `TEXT` | YES | `NULL` | - | Sözleşme PDF belge adresi |
| `additional_documents` | `JSONB` | YES | `'[]'::jsonb` | - | Ek belgeler URL listesi |
| `proposed_by` | `UUID` | YES | `NULL` | **FK** `REFERENCES profiles(id)` | Değişiklik teklif eden |
| `proposed_changes` | `JSONB` | YES | `NULL` | - | Müzakere aşamasındaki teklifler |
| `termination_requested_by` | `UUID` | YES | `NULL` | **FK** `REFERENCES profiles(id)` | Erken fesih isteyen kullanıcı |
| `termination_date` | `DATE` | YES | `NULL` | - | Talep edilen fesih tarihi |
| `termination_reason` | `TEXT` | YES | `NULL` | - | Fesih gerekçesi |
| `termination_approved` | `BOOLEAN` | YES | `FALSE` | - | Fesih karşı tarafça onaylandı mı? |
| `tax_type` | `tax_type` | YES | `'included'` | - | Vergi tipi |
| `created_at` | `TIMESTAMPTZ` | **NO** | `now()` | - | Oluşturulma tarihi |
| `updated_at` | `TIMESTAMPTZ` | **NO** | `now()` | - | Güncellenme tarihi |

#### Tetikleyici (Trigger)
* **`set_contracts_updated_at`**: `BEFORE UPDATE ON contracts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()`

#### RLS Politikaları (`public.contracts`)
* **`contracts_select_policy`**: `FOR SELECT TO authenticated USING (landlord_id = auth.uid() OR tenant_id = auth.uid() OR agency_id = auth.uid() OR (invitee_email IS NOT NULL AND LOWER(invitee_email) = LOWER(COALESCE(auth.jwt()->>'email', ''))))`
* **`contracts_insert_policy`**: `FOR INSERT TO authenticated WITH CHECK (landlord_id = auth.uid() OR agency_id = auth.uid())`
* **`contracts_update_policy`**: `FOR UPDATE TO authenticated USING (landlord_id = auth.uid() OR agency_id = auth.uid() OR tenant_id = auth.uid() OR tenant_id IS NULL OR (invitee_email IS NOT NULL AND LOWER(invitee_email) = LOWER(COALESCE(auth.jwt()->>'email', ''))))`
* **`contracts_delete_policy`**: `FOR DELETE TO authenticated USING (landlord_id = auth.uid() OR agency_id = auth.uid())`

> **Not:** Eski politikalar (`landlord_manage_contracts`, `tenant_view_update_contracts`, `tenant_respond_contract`) kaldırıldı ve acente desteği ile yeniden yazıldı.

---

### 2.4 `rent_payments`
Aylık kira ve bina/fatura ödeme kalemlerini saklar.

#### Tablo Yapısı
| Sütun Adı | Veri Tipi | Nullable | Varsayılan Değer | Kısıtlamalar & İlişkiler | Açıklama |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `id` | `UUID` | **NO** | `gen_random_uuid()` | **PK** | Ödeme kaydı ID |
| `property_id` | `UUID` | **NO** | - | **FK** `REFERENCES properties(id) ON DELETE CASCADE` | Mülk ID |
| `contract_id` | `UUID` | YES | `NULL` | **FK** `REFERENCES contracts(id) ON DELETE CASCADE` | Sözleşme ID |
| `tenant_id` | `UUID` | YES | `NULL` | **FK** `REFERENCES profiles(id)` | Kiracı ID |
| `title` | `TEXT` | **NO** | `'Kira'` | - | Kalem adı (`'Kira'`, `'İnternet'`, vb.) |
| `amount` | `NUMERIC` | **NO** | - | - | Tutar |
| `currency` | `TEXT` | **NO** | `'EUR'` | - | Para birimi |
| `due_date` | `DATE` | **NO** | - | - | Son ödeme tarihi |
| `declared_at` | `TIMESTAMPTZ` | YES | `NULL` | - | Kiracının ödedim beyan tarihi |
| `paid_at` | `TIMESTAMPTZ` | YES | `NULL` | - | Ev sahibinin ödemeyi onayladığı tarih |
| `status` | `rent_payment_status`| **NO** | `'pending'` | - | Ödeme durumu |
| `receiver_type` | `TEXT` | **NO** | `'owner'` | - | Alıcı türü (`'owner'`, `'third_party'`) |
| `receipt_url` | `TEXT` | YES | `NULL` | - | Ödeme dekontu URL |
| `invoice_url` | `TEXT` | YES | `NULL` | - | Fatura belgesi URL |
| `owner_note` | `TEXT` | YES | `NULL` | - | Notlar |
| `dispute_reason` | `TEXT` | YES | `NULL` | - | Ödeme itiraz nedeni |
| `disputed_by` | `UUID` | YES | `NULL` | **FK** `REFERENCES profiles(id)` | İtiraz eden kullanıcı |
| `created_at` | `TIMESTAMPTZ` | **NO** | `now()` | - | Kayıt tarihi |
| `updated_at` | `TIMESTAMPTZ` | **NO** | `now()` | - | Güncelleme tarihi |

#### Unique Kısıtlaması
* `rent_payments_contract_due_date_title_key`: `UNIQUE NULLS NOT DISTINCT (contract_id, due_date, title)`

#### RLS Politikaları (`public.rent_payments`)
* **`landlord_select_rent_payments`**: `FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM properties p WHERE p.id = rent_payments.property_id AND p.landlord_id = auth.uid()))`
* **`tenant_select_rent_payments`**: `FOR SELECT TO authenticated USING (tenant_id = auth.uid())`
* **`tenant_update_rent_payments`**: `FOR UPDATE TO authenticated USING (tenant_id = auth.uid()) WITH CHECK (tenant_id = auth.uid())`
* **`landlord_update_rent_payments`**: `FOR UPDATE TO authenticated USING (EXISTS (SELECT 1 FROM properties p WHERE p.id = property_id AND p.landlord_id = auth.uid())) WITH CHECK (EXISTS (SELECT 1 FROM properties p WHERE p.id = property_id AND p.landlord_id = auth.uid()))`

---

### 2.5 `maintenance_requests`
Bakım ve arıza bildirimlerini saklar.

#### Tablo Yapısı
| Sütun Adı | Veri Tipi | Nullable | Varsayılan Değer | Kısıtlamalar & İlişkiler | Açıklama |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `id` | `UUID` | **NO** | `gen_random_uuid()` | **PK** | Talep ID |
| `property_id` | `UUID` | **NO** | - | **FK** `REFERENCES properties(id) ON DELETE CASCADE` | Mülk ID |
| `reporter_id` | `UUID` | **NO** | - | **FK** `REFERENCES profiles(id)` | Bildiren kullanıcı ID |
| `title` | `TEXT` | **NO** | - | - | Arıza başlığı |
| `description` | `TEXT` | **NO** | - | - | Arıza detaylı açıklaması |
| `status` | `TEXT` | **NO** | `'pending'` | `CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled'))` | Durumu |
| `priority` | `TEXT` | **NO** | `'medium'` | `CHECK (priority IN ('low', 'medium', 'high', 'emergency'))` | Öncelik derecesi |
| `payment_responsibility`| `TEXT` | **NO** | `'undecided'` | `CHECK (payment_responsibility IN ('landlord', 'tenant', 'shared', 'undecided'))` | Ödeme sorumlusu |
| `estimated_cost` | `NUMERIC` | YES | `NULL` | - | Tahmini maliyet |
| `actual_cost` | `NUMERIC` | YES | `NULL` | - | Gerçekleşen harcama |
| `currency` | `TEXT` | **NO** | `'EUR'` | - | Para birimi |
| `created_at` | `TIMESTAMPTZ` | **NO** | `now()` | - | Kayıt tarihi |
| `updated_at` | `TIMESTAMPTZ` | **NO** | `now()` | - | Güncelleme tarihi |

#### RLS Politikaları (`public.maintenance_requests`)
* **`"Users can view maintenance requests"`**: `FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM properties p WHERE p.id = maintenance_requests.property_id AND (p.landlord_id = auth.uid() OR p.tenant_id = auth.uid())))`
* **`"Users can update maintenance requests"`**: `FOR UPDATE TO authenticated USING (EXISTS (SELECT 1 FROM properties p WHERE p.id = maintenance_requests.property_id AND (p.landlord_id = auth.uid() OR p.tenant_id = auth.uid())))`
* **`"Users can delete maintenance requests"`**: `FOR DELETE TO authenticated USING (EXISTS (SELECT 1 FROM properties p WHERE p.id = maintenance_requests.property_id AND p.landlord_id = auth.uid()))`

---

### 2.6 `maintenance_messages`
Arıza talepleri altındaki sohbet mesajlarını saklar.

#### Tablo Yapısı
| Sütun Adı | Veri Tipi | Nullable | Varsayılan Değer | Kısıtlamalar & İlişkiler | Açıklama |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `id` | `UUID` | **NO** | `gen_random_uuid()` | **PK** | Mesaj ID |
| `request_id` | `UUID` | **NO** | - | **FK** `REFERENCES maintenance_requests(id) ON DELETE CASCADE` | Bakım talebi ID |
| `sender_id` | `UUID` | **NO** | - | **FK** `REFERENCES profiles(id)` | Gönderen kullanıcı ID |
| `message` | `TEXT` | **NO** | - | - | Mesaj metni |
| `attachments` | `JSONB` | YES | `'[]'::jsonb` | - | Eklenen resim URL dizisi |
| `created_at` | `TIMESTAMPTZ` | **NO** | `now()` | - | Gönderilme zamanı |

#### RLS Politikaları (`public.maintenance_messages`)
* **`"Users can view maintenance messages"`**: `FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM maintenance_requests mr JOIN properties p ON p.id = mr.property_id WHERE mr.id = maintenance_messages.request_id AND (p.landlord_id = auth.uid() OR p.tenant_id = auth.uid())))`
* **`"Users can insert maintenance messages"`**: `FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM maintenance_requests mr JOIN properties p ON p.id = mr.property_id WHERE mr.id = request_id AND (p.landlord_id = auth.uid() OR p.tenant_id = auth.uid())))`

---

### 2.7 `activity_logs`
Mülkteki tüm finansal ve idari eylemlerin zaman çizelgesi kaydı.

#### Tablo Yapısı
| Sütun Adı | Veri Tipi | Nullable | Varsayılan Değer | Kısıtlamalar & İlişkiler | Açıklama |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `id` | `UUID` | **NO** | `gen_random_uuid()` | **PK** | Günlük kaydı ID |
| `property_id` | `UUID` | **NO** | - | **FK** `REFERENCES properties(id) ON DELETE CASCADE` | Mülk ID |
| `type` | `TEXT` | **NO** | - | - | Olay türü |
| `metadata` | `JSONB` | YES | `'{}'::jsonb` | - | Ek parametreler |
| `created_at` | `TIMESTAMPTZ` | **NO** | `now()` | - | Olay zamanı |

#### RLS Politikaları (`public.activity_logs`)
* **`landlord_select_activity_logs`**: `FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM properties p WHERE p.id = activity_logs.property_id AND p.landlord_id = auth.uid()))`
* **`tenant_select_activity_logs`**: `FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM properties p WHERE p.id = activity_logs.property_id AND p.tenant_id = auth.uid()))`
* **`user_insert_activity_logs`**: `FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM properties p WHERE p.id = property_id AND (p.landlord_id = auth.uid() OR p.tenant_id = auth.uid())))`

---

### 2.8 `notifications`
Kullanıcıya özel sistem bildirimleri.

#### Tablo Yapısı
| Sütun Adı | Veri Tipi | Nullable | Varsayılan Değer | Kısıtlamalar & İlişkiler | Açıklama |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `id` | `UUID` | **NO** | `gen_random_uuid()` | **PK** | Bildirim ID |
| `user_id` | `UUID` | **NO** | - | **FK** `REFERENCES profiles(id) ON DELETE CASCADE` | Alıcı kullanıcı ID |
| `title` | `TEXT` | **NO** | - | - | Bildirim başlığı |
| `body` | `TEXT` | **NO** | - | - | Bildirim gövdesi |
| `type` | `TEXT` | **NO** | - | - | Bildirim kategorisi |
| `is_read` | `BOOLEAN` | **NO** | `FALSE` | - | Okundu bilgisi |
| `data` | `JSONB` | YES | `'{}'::jsonb` | - | Uygulama içi yönlendirme bilgisi |
| `created_at` | `TIMESTAMPTZ` | **NO** | `now()` | - | Bildirim oluşturulma zamanı |

#### RLS Politikaları (`public.notifications`)
* **`"Users can view their own notifications"`**: `FOR SELECT TO authenticated USING (user_id = auth.uid())`
* **`"Users can update their own notifications"`**: `FOR UPDATE TO authenticated USING (user_id = auth.uid())`
* **`"Users can delete their own notifications"`**: `FOR DELETE TO authenticated USING (user_id = auth.uid())`
* **`"Anyone can insert notifications"`**: `FOR INSERT TO authenticated WITH CHECK (true)`

---

### 2.9 `invitations`
Ev sahibinin kiracıyı sisteme davet etmek için oluşturduğu tek kullanımlık jetonlar.

#### Tablo Yapısı
| Sütun Adı | Veri Tipi | Nullable | Varsayılan Değer | Kısıtlamalar & İlişkiler | Açıklama |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `id` | `UUID` | **NO** | `gen_random_uuid()` | **PK** | Davet ID |
| `property_id` | `UUID` | **NO** | - | **FK** `REFERENCES properties(id) ON DELETE CASCADE` | Mülk ID |
| `contract_id` | `UUID` | YES | `NULL` | **FK** `REFERENCES contracts(id) ON DELETE CASCADE` | Bağlı sözleşme ID |
| `token` | `TEXT` | **NO** | - | **UNIQUE** | Benzersiz davet kodu |
| `invitee_email` | `TEXT` | YES | `NULL` | - | Davet edilen e-posta |
| `inviter_name` | `TEXT` | YES | `NULL` | - | Davet eden adı |
| `status` | `TEXT` | **NO** | `'pending'` | `CHECK (status IN ('pending', 'accepted', 'expired', 'revoked'))` | Davet durumu |
| `expires_at` | `TIMESTAMPTZ` | **NO** | - | - | Son kullanım tarihi |
| `created_at` | `TIMESTAMPTZ` | **NO** | `now()` | - | Davet oluşturulma tarihi |

#### RLS Politikaları (`public.invitations`)
* **`landlord_select_invites`**: `FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM properties p WHERE p.id = invitations.property_id AND p.landlord_id = auth.uid()))`
* **`tenant_select_invites`**: `FOR SELECT TO authenticated USING (LOWER(invitee_email) = LOWER(auth.jwt()->>'email') OR status = 'pending')`
* **`landlord_manage_invites`**: `FOR ALL TO authenticated USING (EXISTS (SELECT 1 FROM properties p WHERE p.id = property_id AND p.landlord_id = auth.uid()))`
* **`tenant_update_invite`**: `FOR UPDATE TO authenticated USING (LOWER(invitee_email) = LOWER(auth.jwt()->>'email') OR status = 'pending')`

---

## 3. Görünümler (Views)

### 3.1 `properties_with_names`
Mülklerin ev sahibi, kiracı ve acente ad ve e-posta bilgileri ile birlikte tek sorguda çekilmesini sağlayan veritabanı görünümüdür.

```sql
DROP VIEW IF EXISTS public.properties_with_names CASCADE;

CREATE VIEW public.properties_with_names AS
SELECT 
    p.*,
    l.full_name AS landlord_name,
    l.email AS landlord_email,
    t.full_name AS tenant_name,
    t.email AS tenant_email,
    a.company_name AS agency_name,
    a.email AS agency_email
FROM public.properties p
LEFT JOIN public.profiles l ON p.landlord_id = l.id
LEFT JOIN public.profiles t ON p.tenant_id = t.id
LEFT JOIN public.profiles a ON p.agency_id = a.id;

ALTER VIEW public.properties_with_names SET (security_invoker = on);
```

---

## 4. Saklı Yordamlar ve RPC Fonksiyonları (Stored Procedures & Complete SQL Bodies)

Aşağıda veritabanında yer alan 14 adet saklı yordamın ve RPC fonksiyonunun **EKSİKSİZ VE TAM PL/pgSQL SQL KODLARI** yer almaktadır:

### 4.1 `generate_missing_rent_payments`
**Açıklama**: Mülkün aktif sözleşmesine bağlı olarak aylık kira ve ev sahibine ödenecek yan gider kalemlerini otomatik üretir, 5 günden eski ödenmiş beyanlarını otomatik onaylar.

```sql
CREATE FUNCTION public.generate_missing_rent_payments(p_property_id uuid) RETURNS void
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

  -- No active contract → nothing to do
  IF v_contract_id IS NULL OR v_monthly_rent IS NULL OR v_tenant_id IS NULL THEN
    RETURN;
  END IF;

  -- AUTO-APPROVE: Mark 'declared' as 'paid' after 5 days
  FOR v_approved_row IN
    UPDATE public.rent_payments
    SET status = 'paid', paid_at = (declared_at + interval '5 days')
    WHERE contract_id = v_contract_id
      AND status = 'declared'
      AND declared_at < (now() - interval '5 days')
    RETURNING id, due_date
  LOOP
    INSERT INTO public.activity_logs (property_id, type, metadata)
    VALUES (p_property_id, 'rent_auto_approved',
            jsonb_build_object('month', v_approved_row.due_date));
  END LOOP;

  -- CLEANUP: Remove pending rows before contract start month
  DELETE FROM public.rent_payments
  WHERE contract_id = v_contract_id
    AND status = 'pending'
    AND date_trunc('month', due_date) < date_trunc('month', v_start_date);

  -- Generate rows from start up to and including the CURRENT month (not future)
  v_current_date := (date_trunc('month', v_start_date) + (v_due_day - 1) * interval '1 day')::date;
  v_end_date     := (date_trunc('month', now()) + (v_due_day - 1) * interval '1 day')::date;

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

    -- B. Masraf kalemleri: sadece receiver = 'owner' (kiracı → ev sahibi) olanlar
    IF jsonb_array_length(v_expenses_cfg) > 0 THEN
      FOR v_expense IN SELECT jsonb_array_elements(v_expenses_cfg)
      LOOP
        v_exp_name     := v_expense->>'name';
        v_exp_amount   := COALESCE((v_expense->>'amount')::numeric, 0);
        v_exp_receiver := v_expense->>'receiver';

        IF v_exp_name IS NOT NULL AND v_exp_receiver = 'owner' THEN
          INSERT INTO public.rent_payments
            (property_id, contract_id, tenant_id, amount, currency, due_date, status, title, receiver_type)
          VALUES
            (p_property_id, v_contract_id, v_tenant_id, v_exp_amount, v_currency, v_current_date, 'pending', v_exp_name, 'owner')
          ON CONFLICT (contract_id, due_date, title)
          DO UPDATE SET
            -- If an invoice was uploaded OR the amount is manually set (> 0), DO NOT overwrite it!
            amount    = CASE 
                          WHEN rent_payments.invoice_url IS NOT NULL THEN rent_payments.amount 
                          WHEN rent_payments.amount > 0 THEN rent_payments.amount 
                          ELSE EXCLUDED.amount 
                        END,
            currency  = CASE 
                          WHEN rent_payments.invoice_url IS NOT NULL THEN rent_payments.currency 
                          WHEN rent_payments.amount > 0 THEN rent_payments.currency 
                          ELSE EXCLUDED.currency 
                        END,
            tenant_id = COALESCE(EXCLUDED.tenant_id, rent_payments.tenant_id)
          WHERE rent_payments.status = 'pending';
        END IF;
      END LOOP;
    END IF;

    v_current_date := (date_trunc('month', v_current_date + interval '1.5 month') + (v_due_day - 1) * interval '1 day')::date;
  END LOOP;
END;
$$;
```

---

### 4.2 `accept_contract`
**Açıklama**: Davet token'ı üzerinden kiracının sözleşmeyi kabul etmesini sağlar. Kiracıyı mülke atar ve sözleşmeyi aktif yapar.

```sql
CREATE FUNCTION public.accept_contract(contract_token text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_contract_id UUID;
    v_property_id UUID;
    v_invitee_email TEXT;
    v_user_id UUID;
    v_user_email TEXT;
BEGIN
    v_user_id    := auth.uid();
    v_user_email := auth.jwt() ->> 'email';

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT id, property_id, invitee_email
    INTO v_contract_id, v_property_id, v_invitee_email
    FROM contracts
    WHERE token = contract_token
      AND status IN ('pending', 'negotiating')
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Contract not found or already accepted';
    END IF;

    -- Token eşleşti = yeterli. Email eşleşmesi bonus güvence.
    -- İkisinden biri yeterli: token zaten doğrulandı (WHERE clause),
    -- email kontrolü ek bir kısıtlama değil, sadece loglama amaçlı.
    -- (Farklı email ile gelen Apple/Google kullanıcıları da geçebilir)

    UPDATE contracts
    SET status    = 'active',
        tenant_id = v_user_id
    WHERE id = v_contract_id;

    UPDATE properties
    SET tenant_id = v_user_id
    WHERE id = v_property_id
      AND tenant_id IS NULL;
END;
$$;
```

---

### 4.3 `accept_invitation`
**Açıklama**: Mülk davet jetonunu doğrular, kiracıyı mülkle eşleştirir ve otomatik taslak sözleşme oluşturur.

```sql
CREATE FUNCTION public.accept_invitation(p_invite_token text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_property_id UUID;
    v_invitee_email TEXT;
    v_user_id UUID;
    v_user_email TEXT;
    v_start_date DATE;
    v_end_date DATE;
    v_contract_url TEXT;
BEGIN
    v_user_id := auth.uid();
    v_user_email := auth.jwt() ->> 'email';

    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;

    SELECT property_id, invitee_email 
    INTO v_property_id, v_invitee_email
    FROM invitations
    WHERE token = p_invite_token AND status = 'pending'  -- ← p_ prefix
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invitation not found or already accepted';
    END IF;

    -- Email soft check (Apple relay geçişi)
    IF LOWER(v_invitee_email) != LOWER(v_user_email)
       AND v_user_email NOT LIKE '%@privaterelay.appleid.com' THEN
        RAISE EXCEPTION 'This invitation was sent to %, but you are logged in as %', 
            v_invitee_email, v_user_email;
    END IF;

    SELECT start_date::date, end_date::date, contract_url
    INTO v_start_date, v_end_date, v_contract_url
    FROM contracts
    WHERE property_id = v_property_id AND status = 'active'
    LIMIT 1;

    UPDATE invitations
    SET status = 'accepted'
    WHERE token = p_invite_token;  -- ← p_ prefix

    INSERT INTO leases (property_id, tenant_id, tenant_email, start_date, end_date, status, contract_pdf_url, invitation_token)
    VALUES (v_property_id, v_user_id, v_user_email, v_start_date, v_end_date, 'active', v_contract_url, p_invite_token)  -- ← p_ prefix
    ON CONFLICT (invitation_token) DO NOTHING;

    UPDATE properties
    SET tenant_id = v_user_id
    WHERE id = v_property_id AND tenant_id IS NULL;

END;
$$;
```

---

### 4.4 `propose_contract_changes`
**Açıklama**: Sözleşme şartlarında (kira, depozito, son ödeme günü, giderler vb.) çift taraflı revizyon teklifi başlatır.

```sql
CREATE FUNCTION public.propose_contract_changes(p_contract_id uuid, p_changes jsonb) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_current_status TEXT;
  v_landlord_id UUID;
  v_tenant_id UUID;
BEGIN
  SELECT status::text, landlord_id, tenant_id
  INTO v_current_status, v_landlord_id, v_tenant_id
  FROM contracts
  WHERE id = p_contract_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Contract not found';
  END IF;

  -- Security check: Only participants can propose changes
  IF auth.uid() NOT IN (v_landlord_id, v_tenant_id) THEN
    RAISE EXCEPTION 'Unauthorized: Only landlord or tenant can propose terms/counter-offers';
  END IF;

  -- Logic depends on who is proposing and what is the current state
  IF auth.uid() = v_landlord_id AND (v_current_status = 'negotiating' OR v_current_status = 'pending') THEN
    -- LANDLORD updating initial draft/invite
    UPDATE contracts
    SET
      monthly_rent     = COALESCE((p_changes->>'monthly_rent')::NUMERIC, monthly_rent),
      currency         = COALESCE(p_changes->>'currency', currency),
      deposit_amount   = COALESCE((p_changes->>'deposit_amount')::NUMERIC, deposit_amount),
      deposit_currency = COALESCE(p_changes->>'deposit_currency', p_changes->>'currency', deposit_currency),
      due_day          = COALESCE((p_changes->>'due_day')::INTEGER, due_day),
      start_date       = COALESCE((p_changes->>'start_date')::TIMESTAMPTZ, start_date),
      end_date         = COALESCE((p_changes->>'end_date')::TIMESTAMPTZ, end_date),
      expenses_config  = COALESCE(p_changes->'expenses_config', expenses_config),
      tenant_feedback  = NULL,
      proposed_changes = NULL,
      proposed_by      = NULL,
      status           = 'pending'::public.contract_status,
      updated_at       = now()
    WHERE id = p_contract_id;
  ELSE
    -- ANY PARTY proposing a revision to be accepted by the other
    UPDATE contracts
    SET
      proposed_changes = p_changes,
      proposed_by      = auth.uid(),
      status           = 'revision_requested'::public.contract_status,
      updated_at       = now()
    WHERE id = p_contract_id;
  END IF;
END;
$$;
```

---

### 4.5 `accept_proposed_changes`
**Açıklama**: Teklif edilen sözleşme revizyonunu kabul ederek ana sözleşme sütunlarını günceller.

```sql
CREATE FUNCTION public.accept_proposed_changes(p_contract_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_landlord_id UUID;
  v_tenant_id UUID;
  v_proposed_by UUID;
  v_changes JSONB;
  v_current_end_date TIMESTAMPTZ;
  v_prev_status TEXT;
BEGIN
  -- We assume if status was revision_requested, and it wasn't active, it should go back to its transition state
  SELECT landlord_id, tenant_id, proposed_by, proposed_changes, end_date, status::text
  INTO v_landlord_id, v_tenant_id, v_proposed_by, v_changes, v_current_end_date, v_prev_status
  FROM contracts
  WHERE id = p_contract_id AND status IN ('revision_requested', 'termination_requested');

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Contract not found or not in a pending state';
  END IF;

  IF auth.uid() NOT IN (v_landlord_id, v_tenant_id) THEN
    RAISE EXCEPTION 'Only participants can accept proposed changes';
  END IF;

  IF auth.uid() = v_proposed_by THEN
    RAISE EXCEPTION 'You cannot accept your own proposed changes';
  END IF;

  IF v_changes IS NULL THEN
    RAISE EXCEPTION 'No proposed changes found';
  END IF;

  -- Handle Termination Proposal
  IF v_changes ? 'is_termination' AND (v_changes->>'is_termination')::boolean = true THEN
    UPDATE contracts
    SET
      end_date = (v_changes->>'new_end_date')::timestamptz,
      status = 'active',
      termination_approved = true,
      proposed_changes = NULL,
      proposed_by = NULL,
      updated_at = now()
    WHERE id = p_contract_id;
  ELSE
    -- Handle standard Revision Proposal
    UPDATE contracts
    SET
      monthly_rent      = COALESCE((v_changes->>'monthly_rent')::numeric,         monthly_rent),
      deposit_amount    = COALESCE((v_changes->>'deposit_amount')::numeric,       deposit_amount),
      due_day           = COALESCE((v_changes->>'due_day')::integer,              due_day),
      currency          = COALESCE(v_changes->>'currency',                         currency),
      start_date        = COALESCE((v_changes->>'start_date')::timestamptz,       start_date),
      end_date          = COALESCE((v_changes->>'end_date')::timestamptz,         end_date),
      tax_type          = COALESCE((v_changes->>'tax_type')::public.tax_type,     tax_type),
      expenses_config   = COALESCE(v_changes->'expenses_config',                  expenses_config),
      proposed_changes  = NULL,
      proposed_by       = NULL,
      -- If tenant has already joined, it stays active, else stays pending
      status            = CASE 
                            WHEN v_tenant_id IS NOT NULL THEN 'active'::public.contract_status
                            ELSE 'pending'::public.contract_status
                          END,
      updated_at        = now()
    WHERE id = p_contract_id;
  END IF;
END;
$$;
```

---

### 4.6 `decline_proposed_changes`
**Açıklama**: Sözleşme revizyon teklifini reddederek sözleşmeyi önceki aktif/bekleyen durumuna döndürür.

```sql
CREATE FUNCTION public.decline_proposed_changes(p_contract_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_landlord_id UUID;
  v_tenant_id UUID;
  v_proposed_by UUID;
  v_current_status TEXT;
  v_has_active_invite BOOLEAN;
BEGIN
  SELECT landlord_id, tenant_id, proposed_by, status::text
  INTO v_landlord_id, v_tenant_id, v_proposed_by, v_current_status
  FROM contracts
  WHERE id = p_contract_id AND status IN ('revision_requested', 'negotiating', 'termination_requested');

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Contract not found or not in a negotiable state';
  END IF;

  -- Security: Anyone who is a participant can decline/cancel
  IF auth.uid() NOT IN (v_landlord_id, v_tenant_id) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  -- Determine the fallback status
  -- Logic: If it has a tenant_id, it means the tenant has already joined, so return to 'active'.
  -- If it was a termination request, it must go back to 'active'.
  -- If no tenant_id, it's still in the invitation/draft phase, so return to 'pending'.
  UPDATE contracts
  SET
    proposed_changes = NULL,
    proposed_by      = NULL,
    tenant_feedback  = NULL,
    status           = CASE 
                        WHEN v_current_status = 'termination_requested' THEN 'active'::public.contract_status
                        WHEN v_tenant_id IS NOT NULL THEN 'active'::public.contract_status
                        ELSE 'pending'::public.contract_status
                      END,
    updated_at       = now()
  WHERE id = p_contract_id;
END;
$$;
```

---

### 4.7 `propose_contract_termination`
**Açıklama**: Yürürlükteki sözleşmenin vaktinden önce sonlandırılması için erken fesih talebi başlatır.

```sql
CREATE FUNCTION public.propose_contract_termination(p_contract_id uuid, p_termination_date timestamp with time zone) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
DECLARE
  v_landlord_id UUID;
  v_tenant_id UUID;
  v_status TEXT;
BEGIN
  SELECT landlord_id, tenant_id, status::text
  INTO v_landlord_id, v_tenant_id, v_status
  FROM contracts
  WHERE id = p_contract_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Contract not found';
  END IF;

  IF auth.uid() NOT IN (v_landlord_id, v_tenant_id) THEN
    RAISE EXCEPTION 'Only the landlord or tenant can propose termination';
  END IF;

  IF v_status != 'active' THEN
    RAISE EXCEPTION 'Cannot propose termination on a contract with status: %', v_status;
  END IF;

  UPDATE contracts
  SET
    proposed_changes = jsonb_build_object(
      'is_termination', true,
      'new_end_date', p_termination_date
    ),
    proposed_by = auth.uid(),
    status = 'termination_requested',
    updated_at = now()
  WHERE id = p_contract_id;
END;
$$;
```

---

### 4.8 `leave_property`
**Açıklama**: Kiracının evden ayrılması durumunda mülk ilişkisini temizler ve aktif sözleşmeyi expired durumuna getirir.

```sql
CREATE FUNCTION public.leave_property(p_property_id uuid, p_invite_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_landlord_id uuid;
    v_tenant_id uuid;
BEGIN
    -- 1. Get property ownership info
    SELECT landlord_id, tenant_id INTO v_landlord_id, v_tenant_id
    FROM properties
    WHERE id = p_property_id;

    -- 2. Security Check: Only the landlord or the current tenant can call this
    IF auth.uid() != v_landlord_id AND auth.uid() != v_tenant_id THEN
        RAISE EXCEPTION 'Unauthorized: Only the landlord or the tenant of this property can perform this action.';
    END IF;

    -- 3. Atomically clear the property and delete the invitation
    
    -- Clear tenant from property
    UPDATE properties
    SET tenant_id = NULL
    WHERE id = p_property_id;

    -- Delete the specific invitation record
    DELETE FROM invitations
    WHERE id = p_invite_id AND property_id = p_property_id;

END;
$$;
```

---

### 4.9 `delete_own_account`
**Açıklama**: Giriş yapmış kullanıcının profilini ve auth.users hesabını güvenli bir şekilde siler.

```sql
CREATE FUNCTION public.delete_own_account() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_user_id UUID;
BEGIN
  -- 1. Giriş yapmış kullanıcının ID'sini al
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- 2. Kiracı (Tenant) referanslarını temizle
  -- Mülkleri ve kontratları silmiyoruz, sadece kiracı referansını boşa çıkarıyoruz
  UPDATE public.properties SET tenant_id = NULL WHERE tenant_id = v_user_id;
  UPDATE public.contracts SET tenant_id = NULL WHERE tenant_id = v_user_id;
  
  -- 3. İlişkili kiracı kayıtlarını (leases) sil
  DELETE FROM public.leases WHERE tenant_id = v_user_id;

  -- 4. Bakım talepleri (maintenance_requests) referanslarını temizle
  UPDATE public.maintenance_requests SET reporter_id = NULL WHERE reporter_id = v_user_id;

  -- 5. Eğer kullanıcı bir ev sahini (Landlord) ise, ona ait mülkleri sil
  -- (Bu işlem cascade sayesinde o mülke ait ödemeleri ve kontratları da temizler)
  DELETE FROM public.properties WHERE landlord_id = v_user_id;

  -- 6. Kullanıcının profilini sil
  DELETE FROM public.profiles WHERE id = v_user_id;

  -- 7. Son olarak auth.users tablosundan sil (Bu asıl hesabı yok eder)
  DELETE FROM auth.users WHERE id = v_user_id;
END;
$$;
```

---

### 4.10 `delete_old_notifications`
**Açıklama**: 30 günden eski bildirimleri veritabanından temizler.

```sql
CREATE FUNCTION public.delete_old_notifications() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  DELETE FROM public.notifications
  WHERE created_at < now() - interval '1 month';
END;
$$;
```

---

### 4.11 `handle_new_user`
**Açıklama**: Yeni kaydolan auth kullanıcısı için otomatik profiles kaydı oluşturur.

```sql
CREATE FUNCTION public.handle_new_user() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', 'Kullanıcı'),
    COALESCE(new.raw_user_meta_data->>'role', 'tenant') -- Rol yoksa 'tenant' olarak kaydet
  );
  RETURN new;
END;
$$;
```

---

### 4.12 `check_is_landlord_of_property`
**Açıklama**: Kullanıcının verilen mülkün ev sahibi olup olmadığını doğrular.

```sql
CREATE FUNCTION public.check_is_landlord_of_property(p_id uuid, u_id uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.properties WHERE id = p_id AND landlord_id = u_id
  );
END;
$$;
```

---

### 4.13 `check_is_tenant_of_property`
**Açıklama**: Kullanıcının verilen mülkün kiracısı olup olmadığını doğrular.

```sql
CREATE FUNCTION public.check_is_tenant_of_property(p_id uuid, u_id uuid) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.leases WHERE property_id = p_id AND tenant_id = u_id
  );
END;
$$;
```

---

### 4.14 `update_updated_at_column`
**Açıklama**: Tablo güncellemelerinde updated_at alanını otomatik güncelleyen tetikleyici fonksiyonu.

```sql
CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;
```

---

## 5. Depolama Alanları (Storage Buckets) & Erişim Politikaları

### 5.1 `receipts` (Genel Okuma / Kimlik Doğrulamalı Yükleme)
* **Public**: `true`
* **Erişim Politikaları**:
  * **Yükleme**: `bucket_id = 'receipts' AND (storage.foldername(name))[1] = auth.uid()::text`
  * **Okuma**: `bucket_id = 'receipts'` (Herkese Açık)

### 5.2 `contracts` (Genel Okuma / Kimlik Doğrulamalı Yükleme)
* **Public**: `true`
* **Erişim Politikaları**:
  * **Yükleme**: `bucket_id = 'contracts' AND (storage.foldername(name))[1] = auth.uid()::text`
  * **Okuma**: `bucket_id = 'contracts'` (Herkese Açık)

### 5.3 `maintenance` (Genel Okuma / Kimlik Doğrulamalı Yükleme)
* **Public**: `true`
* **Erişim Politikaları**:
  * **Yükleme**: `bucket_id = 'maintenance' AND (storage.foldername(name))[1] = auth.uid()::text`
  * **Okuma**: `bucket_id = 'maintenance'` (Herkese Açık)

---

## 6. Dart / Flutter Domain Model Eşleşme Tablosu

| PostgreSQL Tablosu | Dart Model Sınıfı | Dosya Yolu |
| :--- | :--- | :--- |
| `profiles` | `UserProfile` | [auth_repository.dart](file:///Users/atilbilgeorum/projects/stanomer/lib/features/auth/data/auth_repository.dart) |
| `properties` | `Property` | [property.dart](file:///Users/atilbilgeorum/projects/stanomer/lib/features/property/domain/property.dart) |
| `contracts` | `Contract` | [contract.dart](file:///Users/atilbilgeorum/projects/stanomer/lib/features/property/domain/contract.dart) |
| `rent_payments` | `RentPayment` | [rent_payment.dart](file:///Users/atilbilgeorum/projects/stanomer/lib/features/property/domain/rent_payment.dart) |
| `maintenance_requests` | `MaintenanceRequest` | [maintenance_request.dart](file:///Users/atilbilgeorum/projects/stanomer/lib/features/maintenance/domain/maintenance_request.dart) |
| `maintenance_messages` | `MaintenanceMessage` | [maintenance_message.dart](file:///Users/atilbilgeorum/projects/stanomer/lib/features/maintenance/domain/maintenance_message.dart) |
| `activity_logs` | `ActivityLog` | [activity_log.dart](file:///Users/atilbilgeorum/projects/stanomer/lib/features/property/domain/activity_log.dart) |
| `notifications` | `NotificationItem` | [notification_item.dart](file:///Users/atilbilgeorum/projects/stanomer/lib/features/notifications/domain/notification_item.dart) |
