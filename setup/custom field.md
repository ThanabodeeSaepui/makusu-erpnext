# Custom Fields Setup

Add custom fields to sales documents.

## Steps

1. Go to **Customize Form**
2. Set **Form Type** to the target document
3. Add the fields below, then **Save**

Repeat for each form type.

---

## Form Type: Quotation, Sales Order, Sales Invoice

The following fields are added to **all three** form types.

---

## Field: Sales

| Property | Value |
|----------|-------|
| Field Name | `sales` |
| Label | Sales |
| Type | Select |
| Mandatory | Yes |
| In List View | Yes |

**Options** (one per line):

```
เอ็ม T.0973564287
เก๋
กุ้ง
ต่อ
หนุ่ม
ช่วย
กัน
แอน
บริษัท
M
ฮ้วง
ธนโชติ
Shopee
Lazada
LineShop
TikTok
```

---

## Field: Shipping Type

| Property | Value |
|----------|-------|
| Field Name | `shipping_type` |
| Label | Shipping Type |
| Type | Select |
| Mandatory | Yes |
| In List View | Yes |

**Options** (one per line):

```
แฟลช
แฟลช COD
SPX
Grab
นัดรับที่ขนส่ง
เซลล์รับที่บริษัท
รถบริษัท
ล/ค รับที่บริษัท
LEX
ล/ค เรียกรถมารับ
รถโฟ์คลิฟท์
เซลล์ส่งของ
```
---

## Form Type: Sales Invoice Only

The following fields are added to **Sales Invoice** only.


## Field: Bank Account

| Property | Value |
|----------|-------|
| Field Name | `bank_account` |
| Label | Bank Account |
| Type | Link |
| Options | Bank Account |
| In List View | Yes |

---

## Field: Bank Account No

| Property | Value |
|----------|-------|
| Field Name | `bank_account_no` |
| Label | Bank Account No |
| Type | Data |
| Fetch From | `bank_account.bank_account_no` |
| Read Only | Yes |
| In List View | Yes |
