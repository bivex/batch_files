import json
import qrcode
import os


def generate_qr_codes(backup_file):
    with open(backup_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    if not os.path.exists("qrcodes"):
        os.makedirs("qrcodes")

    for service in data.get("services", []):
        name = service.get("name")
        account = service.get("otp", {}).get("account")
        issuer = service.get("otp", {}).get("issuer")
        secret = service.get("secret")

        if not all([name, account, issuer, secret]):
            print(
                f"Skipping service due to missing data: {service.get('name', 'Unknown')}"
            )
            continue

        # Construct the otpauth URI
        # Using a default TOTP for simplicity, as some entries in the .2fas don't specify all OTP parameters
        # e.g., algorithm, digits, period.
        # It's safer to use the 'link' directly if available and complete, but not all entries have it.
        # For entries that have a full 'link', we can use that. Otherwise, construct.
        otp_link = service.get("otp", {}).get("link")

        if otp_link:
            uri = otp_link
        else:
            # Fallback to constructing the URI if link is missing or incomplete
            # URL-encode the issuer and account for the URI
            encoded_issuer = qrcode.util.url_encode(issuer)
            encoded_account = qrcode.util.url_encode(account)
            uri = f"otpauth://totp/{encoded_issuer}:{encoded_account}?secret={secret}&issuer={encoded_issuer}"

        # Generate QR code
        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_L,
            box_size=10,
            border=4,
        )
        qr.add_data(uri)
        qr.make(fit=True)

        img = qr.make_image(fill_color="black", back_color="white")

        # Sanitize name for filename
        filename = (
            f"{name}_{account}.png".replace(" ", "_")
            .replace("/", "-")
            .replace("\\", "-")
            .replace(":", "-")
        )
        img.save(os.path.join("qrcodes", filename))
        print(f"Generated QR code for {name} ({account})")


if __name__ == "__main__":
    backup_file = "2fas-backup-20250920161827.2fas"
    generate_qr_codes(backup_file)
