import json
import qrcode
from reportlab.lib.pagesizes import letter
from reportlab.lib.units import inch
from reportlab.pdfgen import canvas
from io import BytesIO
from PIL import Image  # Import PIL Image
import os
import tempfile

# requirements.txt
# qrcode
# pyotp
# reportlab
# pillow


def generate_pdf_from_backup(backup_file, output_pdf_file="2fas_backup_qrcodes.pdf"):
    with open(backup_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    c = canvas.Canvas(output_pdf_file, pagesize=letter)
    width, height = letter
    left_margin = inch
    right_margin = width - inch
    y_position = height - inch  # Start 1 inch from the top

    c.setFont("Helvetica-Bold", 24)
    c.drawString(left_margin, y_position, "2FAS Backup QR Codes")
    y_position -= 0.75 * inch  # More space after title

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

        otp_link = service.get("otp", {}).get("link")

        if otp_link:
            uri = otp_link
        else:
            encoded_issuer = qrcode.util.url_encode(issuer)
            encoded_account = qrcode.util.url_encode(account)
            uri = f"otpauth://totp/{encoded_issuer}:{encoded_account}?secret={secret}&issuer={encoded_issuer}"

        # Generate QR code in-memory
        qr = qrcode.QRCode(
            version=1,
            error_correction=qrcode.constants.ERROR_CORRECT_H,  # High error correction for print
            box_size=4,
            border=4,
        )
        qr.add_data(uri)
        qr.make(fit=True)

        img = qr.make_image(fill_color="black", back_color="white")

        # Save QR code to a temporary file
        with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as temp_qr_file:
            img.save(temp_qr_file.name, format="PNG")
            temp_qr_path = temp_qr_file.name

        # Check if we need a new page (adjust logic for spacing and QR code size)
        # A service entry including QR code and text takes about 2.5 inches vertical space
        required_space = 2.5 * inch
        if y_position < (
            left_margin + required_space
        ):  # If not enough space, create new page
            c.showPage()
            y_position = height - inch
            c.setFont("Helvetica", 12)

        # Draw service name
        c.setFont("Helvetica-Bold", 14)
        c.drawString(left_margin, y_position, f"Service: {name}")
        y_position -= 0.25 * inch

        # Draw account and issuer
        c.setFont("Helvetica", 10)
        c.drawString(left_margin, y_position, f"Account: {account}")
        y_position -= 0.2 * inch
        c.drawString(left_margin, y_position, f"Issuer: {issuer}")
        y_position -= 0.3 * inch  # More space before QR code

        # Draw QR code. Adjust position and size as needed.
        qr_code_size = 1.75 * inch  # Slightly larger QR code
        c.drawImage(
            temp_qr_path,
            left_margin,
            y_position - qr_code_size,
            width=qr_code_size,
            height=qr_code_size,
        )
        y_position -= (
            qr_code_size + 0.5 * inch
        )  # Move down after drawing QR and some spacing

        # Add a separator line for better visual distinction
        c.line(left_margin, y_position, right_margin, y_position)
        y_position -= 0.25 * inch  # Space after separator

        # Delete the temporary QR code file
        os.remove(temp_qr_path)

    c.save()
    print(f"PDF generated successfully: {output_pdf_file}")


if __name__ == "__main__":
    backup_file = "2fas-backup-20250920161827.2fas"
    generate_pdf_from_backup(backup_file)
