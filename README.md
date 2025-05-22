# zip-and-transfer

A script to automate file batching, compression, delivery, extraction, and tracking.

## 💡 What it does

- Zips unprocessed files in `/mule_local_exchange/API/S3/CSDOC-2`
- Sends ZIP to `/opt/axway/cft/runtime/cronjob`
- Extracts ZIP and sets ownership to `cft`
- Logs every action
- Tracks processed files so they are not duplicated

## 🚀 Usage

```bash
./zip_and_transfer.sh <number_of_files>
