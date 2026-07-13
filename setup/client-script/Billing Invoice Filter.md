```js
// ===============================
// Billing
// ===============================

frappe.ui.form.on("Billing", {
  setup(frm) {
    // Filter Sales Invoice dropdown in child table
    frm.set_query("sales_invoice", "invoices", function (doc, cdt, cdn) {
      let selected_invoices = (doc.invoices || [])
        .filter((row) => row.name !== cdn && row.sales_invoice)
        .map((row) => row.sales_invoice);

      return {
        filters: {
          docstatus: 1,
          customer: doc.customer,
          status: ["in", ["Unpaid", "Partly Paid", "Overdue"]],
          name: ["not in", selected_invoices],
        },
      };
    });
  },

  refresh(frm) {
    toggle_invoice_table(frm);

    if (frm.doc.customer && frm.doc.docstatus === 0) {
      frm.add_custom_button(__("Get Invoices"), function () {
        let existing_invoices = (frm.doc.invoices || [])
          .map((row) => row.sales_invoice)
          .filter(Boolean);

        new frappe.ui.form.MultiSelectDialog({
          doctype: "Sales Invoice",
          target: frm,

          setters: {
            customer: frm.doc.customer,
          },

          get_query() {
            return {
              filters: {
                docstatus: 1,
                customer: frm.doc.customer,
                status: ["in", ["Unpaid", "Partly Paid", "Overdue"]],
                name: ["not in", existing_invoices],
              },
            };
          },

          action(selections) {
            let new_invoices = selections.filter(
              (inv) => !existing_invoices.includes(inv),
            );

            let skipped = selections.length - new_invoices.length;

            if (!new_invoices.length) {
              frappe.msgprint(__("All selected invoices are already added."));
              cur_dialog.hide();
              return;
            }

            frappe.db
              .get_list("Sales Invoice", {
                filters: {
                  name: ["in", new_invoices],
                },
                fields: ["name", "outstanding_amount"],
              })
              .then((results) => {
                const outstanding_map = {};

                results.forEach((r) => {
                  outstanding_map[r.name] = r.outstanding_amount;
                });

                new_invoices.forEach((invoice) => {
                  let row = frm.add_child("invoices");

                  row.sales_invoice = invoice;
                  row.outstanding_amount = outstanding_map[invoice] || 0;
                });

                frm.refresh_field("invoices");
                calculate_total(frm);

                if (skipped > 0) {
                  frappe.show_alert({
                    message: __(
                      "{0} invoice(s) were skipped because they were already added.",
                      [skipped],
                    ),
                    indicator: "orange",
                  });
                }

                cur_dialog.hide();
              });
          },
        });
      });
    }

    calculate_total(frm);
  },

  customer(frm) {
    toggle_invoice_table(frm);

    // Ignore first selection on a new document
    if (!frm.__previous_customer) {
      frm.__previous_customer = frm.doc.customer;
      return;
    }

    // Nothing to clear
    if (!frm.doc.invoices || !frm.doc.invoices.length) {
      frm.__previous_customer = frm.doc.customer;
      return;
    }

    frappe.confirm(
      __("Changing the customer will remove all selected invoices. Continue?"),

      () => {
        frm.clear_table("invoices");
        frm.refresh_field("invoices");

        calculate_total(frm);

        frm.__previous_customer = frm.doc.customer;
      },

      () => {
        frm.set_value("customer", frm.__previous_customer);
      },
    );
  },
});

// ===============================
// Billing Invoice Detail
// ===============================

frappe.ui.form.on("Billing Invoice Detail", {
  sales_invoice(frm, cdt, cdn) {
    let row = locals[cdt][cdn];

    if (!row.sales_invoice) {
      frappe.model.set_value(cdt, cdn, "outstanding_amount", 0);

      return;
    }

    // Duplicate protection
    let duplicate = frm.doc.invoices.some(
      (r) => r.sales_invoice === row.sales_invoice && r.name !== row.name,
    );

    if (duplicate) {
      frappe.msgprint(
        __("Invoice {0} has already been added.", [row.sales_invoice]),
      );

      frappe.model.set_value(cdt, cdn, "sales_invoice", "");
      frappe.model.set_value(cdt, cdn, "outstanding_amount", 0);

      return;
    }

    // Autofill outstanding amount
    frappe.db
      .get_value("Sales Invoice", row.sales_invoice, "outstanding_amount")
      .then((r) => {
        if (r.message) {
          frappe.model.set_value(
            cdt,
            cdn,
            "outstanding_amount",
            r.message.outstanding_amount || 0,
          );
        }
      });
  },

  outstanding_amount(frm) {
    calculate_total(frm);
  },

  invoices_remove(frm) {
    calculate_total(frm);
  },
});

// ===============================
// Helpers
// ===============================

function toggle_invoice_table(frm) {
  const enabled = !!frm.doc.customer && frm.doc.docstatus === 0;

  frm.toggle_enable("invoices", enabled);

  if (!enabled) {
    frm.set_df_property(
      "invoices",
      "description",
      __("Please select a Customer before adding invoices."),
    );
  } else {
    frm.set_df_property("invoices", "description", "");
  }
}

function calculate_total(frm) {
  let total = 0;

  (frm.doc.invoices || []).forEach((row) => {
    total += flt(row.outstanding_amount);
  });

  frm.set_value("total_billing_amount", total);
}
```
