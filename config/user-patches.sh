#!/bin/bash

# This user patches script runs right before starting the daemons.
# Configure SMTP TLS security level for relay to Resend.com

# Set smtp_tls_security_level to encrypt to ensure TLS is mandatory for outbound connections
# This is required for secure relay to services like Resend.com, SendGrid, etc.
postconf -e 'smtp_tls_security_level = encrypt'

# Optionally enable TLS logging for debugging (can be removed in production)
postconf -e 'smtp_tls_loglevel = 1'

postconf -e 'smtp_tls_wrappermode = yes'

# Configure TLS policy for Resend.com specifically to ensure secure connection
# echo "smtp.resend.com secure" >> /etc/postfix/tls_policy
# postmap /etc/postfix/tls_policy

# Set TLS policy map in main configuration
# postconf -e 'smtp_tls_policy_maps = hash:/etc/postfix/tls_policy'

echo 'user-patches.sh: Configured TLS for relay'
