# fullstack-guard

ชุด [Agent Skills](https://docs.anthropic.com/en/docs/claude-code/skills) สำหรับตรวจงาน full-stack ก่อนขึ้นระบบจริง เช่น API ไม่ตรงกับแอป, migration ชนกัน, query ช้า, เขียน UI ซ้ำ และแก้แล้วกระทบ repo อื่น ใช้ได้กับทุก stack รายงานสั้น บอกไฟล์จริง และบอกด้วยว่าอะไรยังไม่ได้ตรวจ

## สารบัญ

- [Skill ที่มี](#skill-ที่มี)
- [การติดตั้ง](#การติดตั้ง)
- [วิธีใช้งาน](#วิธีใช้งาน)
- [ใช้สคริปต์โดยตรง](#ใช้สคริปต์โดยตรง)
- [ผลการทดสอบ](#ผลการทดสอบ)
- [ข้อจำกัด](#ข้อจำกัด)
- [โครงสร้าง repository](#โครงสร้าง-repository)

## Skill ที่มี

| Skill | หน้าที่ | สคริปต์ | ควรใช้ไหม (จากผลเทส) |
|---|---|---|---|
| [`db-performance-check`](skills/db-performance-check/SKILL.md) | หาสาเหตุที่ query ช้า แล้ววัดความเร็วก่อนและหลังแก้ | - | แนะนำ |
| [`api-contract-check`](skills/api-contract-check/SKILL.md) | เช็กว่า API กับแอปที่เรียกใช้ตรงกันไหม ทั้งชื่อ field, ตำแหน่ง, ชนิดข้อมูล, null และ enum | `field_gaps.sh` | ใช้ได้ แต่ต้องลองเพิ่ม |
| [`migration-guard`](skills/migration-guard/SKILL.md) | เช็ก migration ที่ชนกัน, rollback ไม่ได้ หรือเสี่ยงตอน deploy | `check_migrations.sh` | แนะนำ |
| [`component-reuse-check`](skills/component-reuse-check/SKILL.md) | หา UI ที่มีอยู่แล้วก่อนเขียนใหม่ | `build_inventory.sh`, `check_diff.sh` | แนะนำ โดยเฉพาะถ้าใช้ Haiku |
| [`verify-it-runs`](skills/verify-it-runs/SKILL.md) | เปิดแอปแล้วลองใช้ส่วนที่แก้จริง ก่อนบอกว่าเสร็จ | - | ทดลองใช้ |
| [`cross-repo-context`](skills/cross-repo-context/SKILL.md) | ดูว่าแก้แล้วกระทบ repo ไหนบ้าง และจดงานไว้ให้ทำต่อได้ | - | ทดลองใช้ |
| [`ui-ux-review`](skills/ui-ux-review/SKILL.md) | รีวิวหน้าจอตามหลัก UX/UI และ WCAG พร้อมบอกเหตุผล | - | ทดลองใช้ |

## การติดตั้ง

**สิ่งที่ต้องมี**

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) ซึ่งเป็นเครื่องมือเดียวที่ทดสอบแล้ว
- `git` และ POSIX shell สำหรับ Skill ที่มีสคริปต์ บน Windows ต้องใช้ Git Bash หรือ WSL แต่ยังไม่ได้ทดสอบ

**ติดตั้งบางตัวในโปรเจกต์**

```sh
git clone https://github.com/supakritoodza/fullstack-guard-skills.git
cd /path/to/your-project
mkdir -p .claude/skills
cp -R /path/to/fullstack-guard/skills/db-performance-check .claude/skills/
```

**ติดตั้งทุกตัวในโปรเจกต์**

```sh
cp -R /path/to/fullstack-guard/skills/* .claude/skills/
```

เครื่องมืออื่นที่รองรับรูปแบบ Agent Skills ให้วางตาม path ที่เครื่องมือนั้นกำหนด

## วิธีใช้งาน

สั่งงานตามปกติได้เลย Skill ส่วนใหญ่จะทำงานเองถ้าคำสั่งตรงกับงานของมัน ถ้าอยากให้ชัวร์ ให้พิมพ์ชื่อ Skill ไปด้วย

| Skill | ตัวอย่างคำสั่ง | สิ่งที่ควรเตรียม | ผลลัพธ์ |
|---|---|---|---|
| `db-performance-check` | `GET /orders ช้า ช่วยหาสาเหตุและแก้ให้หน่อย` | ฐานข้อมูลทดสอบที่มีข้อมูลใกล้เคียงของจริง | สาเหตุ, เวลาก่อนและหลังแก้ และข้อเสียของวิธีแก้ |
| `api-contract-check` | `ตรวจว่า API ของ users ตรงกับเว็บและแอปมือถือไหม ก่อน release` | path ของ repository ฝั่ง server และ client | จุดที่ไม่ตรงกัน พร้อมไฟล์ทั้งสองฝั่ง |
| `migration-guard` | `ตรวจ migration ของ branch นี้ก่อน merge เข้า main` | branch หลัก และฐานข้อมูลทดสอบที่ลบทิ้งได้ | merge ได้ไหม, อะไรรันผ่าน และมีความเสี่ยงอะไร |
| `component-reuse-check` | `เพิ่มหน้า Settings มีฟอร์มและปุ่มบันทึก` | โปรเจกต์ที่เป็น git repository | ส่วนไหนใช้ของเดิม ต่อยอด หรือเขียนใหม่ |
| `verify-it-runs` | `ใช้ skill verify-it-runs ตรวจว่า endpoint ที่แก้ทำงานจริง` | config ที่ชี้ไปยังบริการในเครื่อง | รันคำสั่งอะไร ได้ผลอะไร และอะไรยังไม่ได้รัน |
| `cross-repo-context` | `จะเปลี่ยนชื่อ field นี้ใน API กระทบอะไรบ้าง และควรทำลำดับไหน` | path ของ repository ที่เกี่ยวข้อง | จุดที่กระทบในแต่ละ repo, ลำดับการแก้ และโน้ต handoff |
| `ui-ux-review` | `รีวิวหน้า Checkout ตามหลัก UX/UI ผู้ใช้คือพนักงานการเงิน` | URL หรือหน้าจอ และกลุ่มผู้ใช้ | ปัญหาเรียงจากหนักไปเบา พร้อมเหตุผลและวิธีแก้ |

**กรณีที่ควรพิมพ์ชื่อ Skill**

- `verify-it-runs` ไม่ถูกเรียกอัตโนมัติใน 3 จาก 4 ชุดทดสอบ
- รีวิว branch ด้วย `component-reuse-check` เพราะถ้าสั่งแค่ "รีวิว" จะไปเรียก `code-review` แทน

**ตัวอย่างรายงาน**

```text
Not safe to release: 2 breaks, 1 risk.

Break  profile form sends `note`, API reads `remark`: the note is dropped
       web src/api/profile.ts:42  vs  api users/handler.go:88
Break  mobile reads "user_name" into a non-null String, API sends `username`: login fails to decode
       mobile UserDto.kt:17  vs  api users/serializer.go:30
Risk   `expires_at` can be null for trial plans, web formats it as a date

Not checked: endpoints outside users, runtime responses (read code only).
```

## ใช้สคริปต์โดยตรง

สคริปต์ทุกตัวอ่านอย่างเดียว ไม่แก้ไฟล์และไม่ต่อ DB เอาไปรันเองหรือใส่ใน CI ได้เลย

```sh
# Migration: เลขซ้ำ, แก้ไฟล์เก่า, ไม่มีไฟล์ down และคำสั่งที่เสี่ยง
skills/migration-guard/scripts/check_migrations.sh main

# API: field ที่แอปใช้แต่ server ไม่รู้จัก
skills/api-contract-check/scripts/field_gaps.sh -b main -e users/profile ./api ./web ./mobile

# UI: รายชื่อ component พร้อมจำนวนที่ใช้ และ UI ที่เขียนเองใน diff
skills/component-reuse-check/scripts/build_inventory.sh
skills/component-reuse-check/scripts/check_diff.sh main
```

`check_migrations.sh` ใช้กับไฟล์ที่ขึ้นต้นด้วยเลข และอ่าน migration ของ golang-migrate, Django, Alembic, Rails และ Laravel ส่วน `field_gaps.sh` อ่าน Go, Python, TypeScript, JavaScript, Kotlin, Java, Swift, Dart และ C#

## ผลการทดสอบ

เทสบน Claude Code ด้วยโจทย์ที่ฝังปัญหาไว้ก่อน แล้วเทียบกันระหว่างไม่มี Skill กับมี Skill ตัวเลขคือจำนวนข้อที่ผ่าน

**โปรเจกต์ที่ใช้:** A คือ Go + Next.js + Kotlin, B คือ Django + DRF และ C คือ Go + Kotlin

| Skill | โจทย์ | Sonnet ไม่มี → มี | Haiku ไม่มี → มี |
|---|---|---|---|
| `db-performance-check` | endpoint ช้า, A | 13/21 → 20/21 | 12/21 → 14/21 |
| | endpoint ช้า, B | 10/14 → 13/14 | 12/14 → 19/21 |
| `api-contract-check` | ตรวจทั้งฟีเจอร์, A | 10/21 → 18/21 | 5/21 → 18/21 |
| | ตรวจทั้งฟีเจอร์, C | 8/10 → 10/10 | 15/15 → 15/15 |
| `migration-guard` | ตรวจก่อน merge, A | 21/21 → 21/21 | 20/21 → 21/21 |
| | ตรวจก่อน merge, B | 11/14 → 12/14 | 16/21 → 18/21 |
| `verify-it-runs` | เพิ่ม field บน endpoint ที่มีบั๊ก, B | 8/10 → 10/10 | 15/15 → 14/15 |
| | เพิ่ม field บน endpoint ที่มีบั๊ก, C | 10/10 → 10/10 | 15/15 → 15/15 |
| `cross-repo-context` | รับงานต่อจากโน้ตเก่า, A | 10/10 → 10/10 | 14/15 → 15/15 |
| `ui-ux-review` | รีวิวหน้าจอโจทย์ยาก, A | 14/18 → 14/18 | 24/27 → 20/27 |

`component-reuse-check` ทดสอบ 68 รอบบนโปรเจกต์จำลอง React และ Django Sonnet ใช้ของเดิมครบเท่ากันที่ 108/108 ส่วน Haiku เขียน component ซ้ำลดลงจาก 3/6 รอบเหลือ 0/6 รอบ

**สรุป**

- `db-performance-check` เห็นผลชัดทั้งสองโปรเจกต์ เพราะบังคับให้วัดความเร็วจริงและบอกข้อเสียของวิธีแก้
- `api-contract-check` เห็นผลมากบนโปรเจกต์ A แต่สคริปต์บางส่วนแก้หลังเห็นโจทย์นั้นแล้ว ส่วนโปรเจกต์ C ซึ่งเล็กกว่า ทั้งสองฝั่งเจอจุดที่ฝังไว้ครบ
- `migration-guard` ต่างกันนิดเดียว ส่วนที่ช่วยจริงคือสคริปต์ที่ตรวจเลขซ้ำได้ทุกครั้ง
- `verify-it-runs`, `cross-repo-context` และ `ui-ux-review` ยังไม่เห็นว่าช่วยอะไรชัด ๆ

ผลแบบละเอียดของ `component-reuse-check` และวิธีรันซ้ำอยู่ที่ [`evals/component-reuse-check`](evals/component-reuse-check/README.md) ส่วนโจทย์ของโปรเจกต์ A, B, C ใช้โค้ดภายในทีม จึงไม่ได้เก็บไว้ใน repo นี้ และรันซ้ำจาก repo นี้ไม่ได้

## ข้อจำกัด

- **เทสยังน้อย:** แต่ละโจทย์รันแค่ 2-3 รอบ ผลอาจเปลี่ยนได้ถ้ารันเยอะกว่านี้
- **คะแนนอาจคลาดเคลื่อน:** ใช้สคริปต์ให้คะแนนจากคำในคำตอบ และต้องแก้เกณฑ์หลายข้อหลังเปิดอ่านคำตอบจริง
- **`check_migrations.sh`:** ส่วนของ Alembic, Rails และ Laravel ยังเทสกับโปรเจกต์ตัวอย่างเท่านั้น ยังไม่เคยลองกับโปรเจกต์จริง
- **`field_gaps.sh`:** เทียบได้แค่ชื่อ field ส่วนชนิดข้อมูล, null และ enum ยังต้องอ่านโค้ดเทียบเอง
- **ยังไม่ได้เทสซ้ำ:** หลังเทสรอบล่าสุด มีการแก้ `SKILL.md` ให้บอกตำแหน่งของสคริปต์ชัดขึ้น

## โครงสร้าง repository

```text
skills/
  <skill-name>/
    SKILL.md        ขั้นตอนการทำงานและหน้าตารายงาน
    scripts/        สคริปต์ตรวจ (มีบาง Skill)
evals/
  component-reuse-check/    เทสบนโปรเจกต์จำลอง
  check-migrations/         เทส check_migrations.sh โดยไม่ใช้ Claude
```
