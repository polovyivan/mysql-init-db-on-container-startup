#!/bin/bash
echo "########### Creating env variables ###########"
ROWS=20
NUMBER_OF_CUSTOMERS=$(( ${ROWS} / 3 + 1))
PAYMENT_TYPES=("VISA" "MASTERCARD" "DISCOVER" "AMEX" "JCB" "CASH")
SQL_SCRIPT_PATH=/tmp/sql/01-init-sql-script.sql
CUSTOMER_IDS=()

echo "########### Creating customer_id array ###########"
for i in $(seq ${NUMBER_OF_CUSTOMERS}); do
  CUSTOMER_IDS+=($(cat /proc/sys/kernel/random/uuid))
done

echo "########### Creating sql script file ###########"
echo "
DROP TABLE IF EXISTS purchase_transaction;

CREATE TABLE purchase_transaction (
id VARCHAR(36) PRIMARY KEY,
payment_type VARCHAR(20) NOT NULL,
amount DECIMAL(19,4),
customer_id VARCHAR(36),
created_at DATETIME NOT NULL
);
" >${SQL_SCRIPT_PATH}

if [ "${ROWS}" -gt 0 ]; then echo "INSERT INTO purchase_transaction VALUES" >> ${SQL_SCRIPT_PATH}; fi

echo "########### Generating insert statement for ${ROWS} rows ###########"
for i in $(seq ${ROWS}); do
  TRANSACTION_ID=$(cat /proc/sys/kernel/random/uuid)
  CUSTOMER_ID=${CUSTOMER_IDS[${RANDOM} % ${#CUSTOMER_IDS[@]}]}
  PAYMENT_TYPE=${PAYMENT_TYPES[${RANDOM} % ${#PAYMENT_TYPES[@]}]}
  AMOUNT=$((1+${RANDOM}%(200-1))).$((${RANDOM} % 99))
  DATE=$(date -d "$((${RANDOM} % 22 + 2000))-$((${RANDOM} % 12 + 1))-$((${RANDOM} % 28 + 1)) $((${RANDOM} % 23 + 1)):$((${RANDOM} % 59 + 1)):$((${RANDOM} % 59 + 1))" '+%Y-%m-%d %H:%M:%S')
  if [ ${i} -eq ${ROWS} ]; then LAST_CHAR=";"; else LAST_CHAR=","; fi
  echo "(\"${TRANSACTION_ID}\",\"${PAYMENT_TYPE}\", \"${AMOUNT}\", \"${CUSTOMER_ID}\", \"${DATE}\")${LAST_CHAR}" >> ${SQL_SCRIPT_PATH}
done

echo "########### Running SQL script against DB ###########"
mysql --user="customer_user" --password="customer_password" --database="customer" < ${SQL_SCRIPT_PATH}

echo "########### Script execution finished! ###########"
