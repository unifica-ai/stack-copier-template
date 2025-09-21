#!/usr/bin/env python3

import logging

logger = logging.getLogger(__name__)

def update_odoobot_name(env):
    """Rename OdooBot to Aly"""
    # The OdooBot user typically has ID 1
    odoobot = env["res.users"].browse(1)
    if odoobot.exists():
        # Update the OdooBot name
        odoobot.write({"name": "Aly"})

        # Also update the partner record associated with OdooBot
        if odoobot.partner_id:
            odoobot.partner_id.write({"name": "Aly"})

        logger.info(f"OdooBot renamed to: {odoobot.name}")
    else:
        logger.warning("OdooBot user with ID 1 not found!")


def update_admin_email(env):
    """Update admin user email address."""
    admin_email = "admin@aly-ai.com"

    # Update the email for admin user (ID 2) and its partner
    admin_user = env["res.users"].browse(2)
    if admin_user.exists():
        admin_user.write({"email": admin_email})
        # Also update the linked partner record
        if admin_user.partner_id:
            admin_user.partner_id.write({"email": admin_email})

        logger.info(f"Updated admin email to: {admin_email}")
    else:
        logger.warning("Admin user with ID 2 not found!")


if __name__ == "__main__":
    # When running with click-odoo, the 'env' variable is already available
    try:
        # noqa: F821
        update_odoobot_name(env)  # noqa: F821
        update_admin_email(env)  # noqa: F821
    except NameError:
        logger.error(
            "This script should be run with click-odoo to provide the 'env' variable"
        )
# +end_src
