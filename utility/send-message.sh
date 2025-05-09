#!/bin/bash

# Define the recipient's email address
recipient="daniel.higgins@umassmed.edu"

# Define the email subject
subject="Test Email"

# Construct the email message
message="Hello,\n\nThis is a test email sent using sendmail."

# Use sendmail to send the email
echo -e "Subject: $subject\n\n$message" | sendmail "$recipient" 