-- Bu SQL kodu, giriş yapmış kullanıcının kendi hesabını uygulama içinden silebilmesini sağlar.
-- Supabase SQL Editor'e yapıştırıp "Run" tuşuna basmanız yeterlidir.

create or replace function public.delete_own_account()
returns void as $$
begin
  -- Giriş yapmış kullanıcının ID'sini alıyoruz
  -- auth.uid() fonksiyonu sadece yetkilendirilmiş isteklerde dolu gelir.
  delete from auth.users where id = auth.uid();
end;
$$ language plpgsql security definer;

-- Güvenlik Notu: "security definer" yetkisi, bu fonksiyonun "admin" yetkisiyle 
-- (kendi kullanıcısını silecek güçte) çalışmasını sağlar. 
-- Ancak içindeki "where id = auth.uid()" koşulu sayesinde 
-- hiçbir kullanıcı bir başkasının hesabını SİLEMEZ.
