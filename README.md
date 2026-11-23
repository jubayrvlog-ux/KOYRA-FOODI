# Koyra Food — Setup & Deployment

এই প্রজেক্টটি মোবাইল-ফ্রেন্ডলি React/Vite ওয়েব অ্যাপ। Authentication, প্রোফাইল, খাবারের মেনু, কার্ট, অর্ডার এবং Admin dashboard চালাতে Supabase backend লাগবে।

## ১) Supabase সেটআপ (একবারই)
1. https://supabase.com এ গিয়ে নতুন project তৈরি করুন।
2. Project → SQL Editor → New query খুলুন।
3. `supabase/schema.sql` ফাইলের সম্পূর্ণ SQL কপি করে Run করুন।
4. Project Settings → API থেকে Project URL এবং `anon` public key কপি করুন।
5. Authentication → URL Configuration-এ আপনার Vercel URL যোগ করুন (Site URL এবং Redirect URLs)।
6. Authentication → Providers → Email চালু রাখুন। চাইলে email confirmation বন্ধ করতে পারেন; চালু থাকলে নতুন ব্যবহারকারীকে Gmail verify করতে হবে।

## ২) নিজের Admin account তৈরি
1. ওয়েবসাইটে নিজের Gmail দিয়ে Sign Up করুন।
2. Supabase → Authentication → Users থেকে নিজের account নিশ্চিত করুন।
3. SQL Editor-এ এই query চালান (নিজের Gmail বসিয়ে):
   `update public.profiles set role='admin' where email='YOUR_GMAIL@gmail.com';`
4. অ্যাপ থেকে Logout করে আবার Login করুন। Admin ট্যাব দেখা যাবে।
**সতর্কতা:** কাউকে admin করবেন না যদি তার ওপর ভরসা না থাকে।

## ৩) GitHub-এ আপলোড
1. ZIP extract করুন।
2. GitHub → New repository → নাম দিন `koyra-food` → Create repository।
3. Add file → Upload files দিয়ে extract করা ফোল্ডারের ভেতরের সব ফাইল আপলোড করে Commit changes দিন।

## ৪) Vercel-এ প্রকাশ
1. https://vercel.com এ GitHub দিয়ে Login করুন।
2. Add New → Project → `koyra-food` repository Import করুন।
3. Framework: Vite (auto detect), Build Command `npm run build`, Output Directory `dist`।
4. Environment Variables যোগ করুন:
   - `VITE_SUPABASE_URL` = Supabase Project URL
   - `VITE_SUPABASE_ANON_KEY` = Supabase anon public key
5. Deploy চাপুন। ভবিষ্যতে GitHub-এ commit করলে Vercel আবার deploy করবে।

## ৫) কীভাবে ব্যবহার করবেন
- কাস্টমার Sign Up/Login করে খাবার দেখবে, কার্টে যোগ করবে, ঠিকানা ও ইউনিয়ন দিয়ে অর্ডার করবে।
- সাত ইউনিয়নের ডেলিভারি চার্জ: কয়রা ২০, মহারাজপুর ৩০, মহেশ্বরীপুর ৫০, উত্তর বেদকাশী ৫০, দক্ষিণ বেদকাশী ৪০, আমাদী ৬০, বাগালী ৪০ টাকা।
- Admin → খাবার যোগ করুন থেকে নাম, দাম, ছবি, ক্যাটাগরি যোগ করুন। কাচ্চি/বার্গার/মোগলাই পরোটার দাম আপনি নিজে নির্ধারণ করবেন।
- Admin → সকল অর্ডার থেকে অর্ডারের স্ট্যাটাস পরিবর্তন করুন।

## গুরুত্বপূর্ণ সীমাবদ্ধতা ও পরবর্তী উন্নয়ন
- এই সংস্করণে GPS লাগে না; গ্রাহক নিজে ইউনিয়ন নির্বাচন করে ঠিকানা লিখবে। এটি ঠিকানা-ভিত্তিক সীমাবদ্ধতা, বাস্তব GPS যাচাই নয়। উপজেলা/ইউনিয়ন নির্বাচনের বাইরে ঠিকানা ঠেকাতে ভবিষ্যতে গ্রাম/এলাকার অনুমোদিত তালিকা যোগ করা ভালো।
- Delivery fee বর্তমানে অ্যাপে নির্ধারিত fixed values; পরবর্তী সংস্করণে Admin UI থেকে fee edit করার ব্যবস্থা যোগ করা যাবে।
- পেমেন্ট এখন Cash on Delivery ভিত্তিক (অর্ডার জমা); bKash/Nagad integration আলাদা merchant credentials ও gateway approval ছাড়া চালু হবে না।
- ছবি আপলোডের জন্য Supabase Storage bucket `food-images` ব্যবহৃত হয়।
- Supabase schema ও environment variables না দিলে live authentication/order/database কাজ করবে না। শুধু ZIP আপলোড করলেই backend নিজে থেকে তৈরি হয় না।
- ডেমো খাবারের ছবি ও নাম আছে; দাম ০ থাকা খাবারগুলো Admin থেকে সঠিক দাম বসানোর আগে অর্ডার করা যাবে না।
