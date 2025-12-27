FROM frappe/erpnext:v15.93.0

# Switch to root to install dependencies if needed (optional)
USER root
# Install any OS-level dependencies here (e.g., specific fonts or libs for PDF generation)
# RUN apt-get update && apt-get install -y ...
RUN apt-get update && apt-get install -y chromium

# Switch back to frappe user
USER frappe

# Run the installation
RUN bench setup-chrome
RUN bench get-app https://github.com/frappe/print_designer --branch main