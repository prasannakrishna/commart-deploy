#!/bin/bash
# Creates all databases needed by Commart microservices
# This runs automatically when the PostgreSQL container starts for the first time

set -e

DATABASES="orderdb sellerdb carrierdb transportdb billing_db deliverydb lineage_db wmsdb paymentdb cartdb userdb authdb storedb communitydb catalogdb customerdb financedb escrowdb subscriptiondb contractdb notificationdb spacedb shipmentdb allocationdb labeldb locationdb disputedb auditdb workflowdb pricingdb inventorydb supplydb"

for db in $DATABASES; do
    echo "Creating database: $db"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
        SELECT 'CREATE DATABASE $db' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$db')\gexec
EOSQL
done

echo "✅ All databases created successfully"
