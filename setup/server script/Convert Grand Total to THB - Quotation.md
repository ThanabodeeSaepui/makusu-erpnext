Script Type: DocType Event
Reference Document Type: Quotation
DocType Event: Before Save

Script
```py
def get_baht_text(num):
    if not num:
        return ""

    number_text = ["ศูนย์", "หนึ่ง", "สอง", "สาม", "สี่", "ห้า", "หก", "เจ็ด", "แปด", "เก้า"]
    unit_text = ["", "สิบ", "ร้อย", "พัน", "หมื่น", "แสน", "ล้าน"]

    # Sandbox-safe string formatting for 2 decimal places
    num_str = "%.2f" % float(num)
    
    parts = num_str.split(".")
    baht = parts[0]
    satang = parts[1] if len(parts) > 1 else "00"

    result = ""

    # 1. Convert the Baht (Integer) portion
    if int(baht) == 0:
        result = "ศูนย์บาท"
    else:
        baht_len = len(baht)
        for i in range(baht_len):
            digit = int(baht[i])
            pos = baht_len - 1 - i

            if digit != 0:
                if pos % 6 == 1:
                    # TENS PLACE FIX: If digit is 1, append nothing so unit_text just adds "สิบ"
                    if digit == 1:
                        pass
                    elif digit == 2:
                        result += "ยี่"
                    else:
                        result += number_text[digit]
                elif pos % 6 == 0 and digit == 1 and i > 0:
                    # ONES PLACE: Use "เอ็ด" if it's 1 and not the only digit
                    result += "เอ็ด"
                else:
                    # All other places
                    result += number_text[digit]

                result += unit_text[pos % 6]

            # Add "Million" marker every 6 digits
            if pos % 6 == 0 and pos > 0:
                result += "ล้าน"

        result += "บาท"

    # 2. Convert the Satang (Decimal) portion
    if int(satang) == 0:
        result += "ถ้วน"
    else:
        satang_len = len(satang)
        for i in range(satang_len):
            digit = int(satang[i])
            pos = satang_len - 1 - i

            if digit != 0:
                if pos == 1:
                    # TENS PLACE FIX FOR SATANG
                    if digit == 1:
                        pass
                    elif digit == 2:
                        result += "ยี่"
                    else:
                        result += number_text[digit]
                elif pos == 0 and digit == 1 and satang[0] != '0':
                    # ONES PLACE: Use "เอ็ด" unless the tens place is 0 (e.g., .01 is หนึ่งสตางค์)
                    result += "เอ็ด"
                else:
                    result += number_text[digit]

                result += unit_text[pos]

        result += "สตางค์"

    return result

# Execution logic
if doc.grand_total:
    doc.custom_thai_baht_text = get_baht_text(doc.grand_total)
else:
    doc.custom_thai_baht_text = "ศูนย์บาทถ้วน"
```
