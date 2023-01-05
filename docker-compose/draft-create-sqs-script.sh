#!/bin/bash

function getUUID() {
  UUID=($(cat /proc/sys/kernel/random/uuid))
}

#function getYear() {
#  YEAR=$((${RANDOM_NUMBER} % 22 + 2000))
#}
#
#function getMonth() {
#  MONTH=($(echo "0$((${RANDOM_NUMBER} % 12 + 1))" | grep -o ..$))
#}
#
#function getDay() {
#  DAY=($(echo "0$((${RANDOM_NUMBER} % 28 + 1))" | grep -o ..$))
#}
#
#function getHour() {
#  HOUR=($(echo "0$((${RANDOM_NUMBER} % 23 + 1))" | grep -o ..$))
#}
#
#function getMinute() {
#  MINUTE=($(echo "0$((${RANDOM_NUMBER} % 59 + 1))" | grep -o ..$))
#}
#
#function getSecond() {
#  SECOND=($(echo "0$((${RANDOM_NUMBER} % 59 + 1))" | grep -o ..$))
#}

function getDate() {
  #  DATE="${YEAR}-${MONTH}-${DAY} ${HOUR}:${MINUTE}:00"
  #     DATE=("$((${RANDOM_NUMBER} % 22 + 2000))-$((${RANDOM_NUMBER} % 12 + 1))-$((${RANDOM_NUMBER} % 28 + 1)) $((${RANDOM_NUMBER} % 23 + 1)):$((${RANDOM_NUMBER} % 59 + 1)):$((${RANDOM_NUMBER} % 59 + 1))")
  DATE=$(date -d "$((${RANDOM_NUMBER} % 22 + 2000))-$((${RANDOM_NUMBER} % 12 + 1))-$((${RANDOM_NUMBER} % 28 + 1)) $((${RANDOM_NUMBER} % 23 + 1)):00:00" '+%Y-%m-%d %H:%M:%S')
}

#function getDate_2() {
#  DATE=$(echo $((${RANDOM_NUMBER} % 22 + 2000))-$((${RANDOM_NUMBER} % 12 + 1))-$((${RANDOM_NUMBER} % 28 + 1)) $((${RANDOM_NUMBER} % 23 + 1)):$((${RANDOM_NUMBER} % 59 + 1)):$((${RANDOM_NUMBER} % 59 + 1)))
#}

#function getCustomerId() {
#  CUSTOMER_ID=${CUSTOMER_IDS[${RANDOM_NUMBER} % ${#CUSTOMER_IDS[@]}]}
#}

function getPaymentType() {
  PAYMENT_TYPE=${PAYMENT_TYPES[${RANDOM_NUMBER} % ${#PAYMENT_TYPES[@]}]}
}

function getAmount() {
  AMOUNT=$((1 + ${RANDOM_NUMBER} % (200 - 1))).$((${RANDOM_NUMBER} % 99))
}

echo "########### Creating env variables ###########"
ROWS=100000
NUMBER_OF_CUSTOMERS=$((${ROWS} / 3))
PAYMENT_TYPES=("VISA" "MASTERCARD" "DISCOVER" "AMEX" "JCB" "CASH")
SQL_SCRIPT_PATH=./01-init-sql-script.sql
#SQL_SCRIPT_PATH=/tmp/sql/01-init-sql-script.sql

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

if [ "${ROWS}" -gt 0 ]; then echo "INSERT INTO purchase_transaction VALUES" >>${SQL_SCRIPT_PATH}; fi

SCRIPT_CONTENT=""

echo "########### Generating insert statement for ${ROWS} rows ###########"
echo ${MAX_NUMBER_OF_TRANSACTION_PER_CUSTOMER}
for ((i = 1; i <= ${NUMBER_OF_CUSTOMERS}; ++i)); do
  getUUID
  RANDOM_NUMBER=$((RANDOM))

  if [ ${i} == ${NUMBER_OF_CUSTOMERS} ]; then
    NUMBER_OF_TRANSACTIONS_FOR_CUSTOMER=${ROWS}
  else
    NUMBER_OF_TRANSACTIONS_FOR_CUSTOMER=$((${RANDOM_NUMBER} % 3 + 2))
  fi

  #  echo "Generating ${NUMBER_OF_TRANSACTIONS_FOR_CUSTOMER} transaction for the customer with id ${UUID}"

  for ((j = 1; j <= ${NUMBER_OF_TRANSACTIONS_FOR_CUSTOMER}; ++j)); do
    #    #    getCustomerId
    #
    #    #  get quantity of transactions for a given customer get the range
    #    # every customer can have between 1-10 transaction
    #    # range of transaction per customer
    #    # 10 transactions 5 customers every customer has
    #    # 10 transactions for 3 customers. Every customer can have no more than 3 transactions
    #    # 1. Calculate number of customers (30% of transactions)
    #    # 2. Define min 1 and max number of transactions per customer
    #    # 3.
    #
    #    # Example
    #    # 100 transactions
    #    # 30 customers
    #    #
    #
#    getYear
#    getMonth
#    getDay
#    getHour
#    getMinute
    RANDOM_NUMBER=$((RANDOM))
    getPaymentType
    getAmount
    getDate
    if [ ${j} == ${ROWS} ]; then LAST_CHAR=";"; else LAST_CHAR=","; fi
    SCRIPT_CONTENT+="(uuid(),\"${PAYMENT_TYPE}\", \"${AMOUNT}\", \"${UUID}\", \"${DATE}\")${LAST_CHAR}\n"
  done

  ROWS=$((ROWS - NUMBER_OF_TRANSACTIONS_FOR_CUSTOMER))
  #  echo "Remaining rows ${ROWS}"
done
echo -e ${SCRIPT_CONTENT} >>${SQL_SCRIPT_PATH}

echo "########### Running SQL script against DB ###########"
mysql --user="customer_user" --password="customer_password" --database="customer" <${SQL_SCRIPT_PATH}

echo "########### Script execution finished! ###########"

#  UUID=($(od -x /dev/urandom | head -1 | awk '{OFS="-"; print $2$3,$4,$5,$6,$7$8$9}'))
