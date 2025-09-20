import json
import pyotp
import os
import time


def get_current_otp_codes(backup_file):
    with open(backup_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    services = []
    for service in data.get("services", []):
        name = service.get("name")
        account = service.get("otp", {}).get("account")
        issuer = service.get("otp", {}).get("issuer")
        secret = service.get("secret")

        if all([name, account, issuer, secret]):
            services.append(
                {"name": name, "account": account, "issuer": issuer, "secret": secret}
            )
        else:
            print(
                f"Skipping service due to missing data: {service.get('name', 'Unknown')}"
            )

    while True:
        os.system("cls" if os.name == "nt" else "clear")
        print("Current One-Time Passwords (Live Update):")
        print("------------------------------------------")

        for service in services:
            try:
                totp = pyotp.TOTP(service["secret"].upper())
                current_otp = totp.now()
                print(f"{service['issuer']} - {service['account']}: {current_otp}")
            except Exception as e:
                print(
                    f"Error generating OTP for {service['name']} ({service['account']}): {e}"
                )
        time.sleep(20)


if __name__ == "__main__":
    backup_file = "2fas-backup-20250920161827.2fas"
    get_current_otp_codes(backup_file)
