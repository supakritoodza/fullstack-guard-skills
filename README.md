# Agent Skills

ชุด Skill สำหรับปัญหาที่เจอจากงานจริง ใช้ได้กับทุก stack ทุก Skill ต้องประหยัด token และเขียนรายงานให้อ่านเหมือนเพื่อนร่วมทีมเขียน

| Skill | ใช้ทำอะไร | สถานะ |
|---|---|---|
| [`component-reuse-check`](skills/component-reuse-check/SKILL.md) | เช็กว่ามี UI อยู่แล้วหรือยัง ก่อนสร้างใหม่ | ทดสอบแล้ว |
| [`migration-guard`](skills/migration-guard/SKILL.md) | เช็ก migration ที่ชนกันก่อน merge | ร่าง ยังไม่ได้ทดสอบ |
| [`db-performance-check`](skills/db-performance-check/SKILL.md) | หาสาเหตุที่ query ช้า แล้ววัดผลก่อน/หลังแก้ | ร่าง ยังไม่ได้ทดสอบ |
| [`ui-ux-review`](skills/ui-ux-review/SKILL.md) | รีวิวหน้าจอตามหลัก UX/UI พร้อมอธิบายเหตุผล | ร่าง ยังไม่ได้ทดสอบ |
| [`cross-repo-context`](skills/cross-repo-context/SKILL.md) | ไล่จุดกระทบข้าม repo และจดงานไว้ทำต่อ session หน้า | ร่าง ยังไม่ได้ทดสอบ |

ติดตั้งทุกตัวแบบเดียวกัน คือคัดลอกโฟลเดอร์ของ Skill ไปไว้ใน `.claude/skills/` ของโปรเจกต์

## `component-reuse-check`

ปัญหาคือ component, icon, ปุ่ม, layout หรือเมนูมีอยู่แล้ว แต่คนหรือ AI ไม่เจอ เลยเขียนใหม่ แล้วแต่ละหน้าก็หน้าตาไม่เหมือนกัน

### ติดตั้ง

คัดลอกโฟลเดอร์ Skill ไปไว้ในโปรเจกต์ ตัวอย่างนี้ใช้กับ Claude Code

```sh
mkdir -p .claude/skills
cp -R /path/to/agent-skills/skills/component-reuse-check .claude/skills/
```

เครื่องมืออื่นที่รองรับ Agent Skills ให้วางตาม path ที่เครื่องมือนั้นกำหนด ตอนนี้ผมทดสอบบน Claude Code อย่างเดียว

ต้องมี `git` และ POSIX shell ส่วนบน Windows ต้องรันผ่าน Git Bash หรือ WSL แต่ยังไม่ได้ทดสอบ

### วิธีใช้

**ตอนเขียน UI ใหม่** สั่งงานตามปกติได้เลย ในการทดสอบ Skill ทำงานเองทุกรอบ

```text
เพิ่มหน้า Settings มีฟอร์มชื่อกับอีเมล ปุ่มบันทึก และปุ่มลบบัญชี
```

**ตอนรีวิว branch** ต้องเรียกชื่อ Skill ตรง ๆ เพราะถ้าสั่งแค่ "รีวิว" มันไม่ทำงานเอง

```text
ใช้ skill component-reuse-check รีวิว branch นี้เทียบกับ main
```

### Input และ Output

- **Input:** งานที่จะทำหรือ branch ที่จะรีวิว และโปรเจกต์ที่เป็น git repo
- **Output:** รายงานสั้น ๆ บอกทีละส่วนว่าใช้ของเดิม ต่อยอด หรือสร้างใหม่

```text
Settings page is done. Reused 8 parts, added 1.

Use     AppShell        src/shell/AppShell.tsx
New     ColorPicker     searched color, swatch, picker: no match

Not checked: only read the code, did not open the page in a browser.
```

### ขั้นตอนการทำงาน

1. `build_inventory.sh` ทำสารบัญ UI พร้อมจำนวนที่ถูกใช้
2. แตกงานเป็นส่วน ๆ แล้วค้นในสารบัญ
3. เขียนโค้ดตามแผน
4. `check_diff.sh` หาปุ่มดิบ, icon ที่ฝังในหน้า, inline style และสีที่ใส่ตรง ๆ

### ผลทดสอบ

ทดสอบ 68 รอบ เทียบ AI ปกติกับ AI ที่มี Skill บน React และ Django สรุปคือ **Sonnet ทำได้ดีอยู่แล้ว Skill จึงไม่ได้ทำให้เจอของเดิมมากขึ้น แต่ Haiku พลาดน้อยลง และรายงานรีวิวสั้นลง**

| ชุดทดสอบ | AI ปกติ | มี Skill |
|---|---|---|
| Sonnet เขียนหน้าใหม่ 24 รอบ: ใช้ของเดิม | 108/108 | 108/108 |
| Haiku เขียนหน้าใหม่ 12 รอบ: รอบที่สร้างซ้ำจริง | 3/6 | 0/6 |
| Sonnet รีวิว เมื่อสั่งหาของซ้ำ 20 รอบ: เจอ | 87/90 | 84/90 |
| Sonnet รีวิว เมื่อสั่งหาของซ้ำ: ความยาวรายงาน (ค่ากลาง) | 372 คำ | 251 คำ |

ข้อจำกัดที่ควรรู้:

- โปรเจกต์ทดสอบเป็นของที่สร้างขึ้นเอง ยังไม่ได้ลองกับ repo จริงของทีม
- ตอนรีวิว Skill พลาด `Notice` 6 จาก 10 รอบ ซึ่งยังไม่ได้แก้
- สั่งรีวิวแบบทั่วไป Skill ไม่ทำงานเลยทั้ง 6 รอบ เพราะ `code-review` ในตัวถูกเรียกแทน
- token รวมตอน Sonnet เขียนหน้าใหม่เพิ่มราว 21% แต่ค่าใช้จ่ายเท่าเดิม

รายละเอียดและวิธีรันซ้ำอยู่ที่ [`evals/component-reuse-check/README.md`](evals/component-reuse-check/README.md)
