-- B. Customer Transactions
-- What is the unique count and total amount for each transaction type?
select txn_type,
count(*) as unique_count,
sum(txn_amount) as total_amont
from customer_transactions
group by txn_type;

-- What is the average total historical deposit counts and amounts for all customers?

select round(count(customer_id)/
               (select count(distinct customer_id)
                from customer_transactions)) as average_deposit_count,
       concat('$', round(avg(txn_amount), 2)) as average_deposit_amount
from customer_transactions
where txn_type = "deposit";

-- For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

with transaction_count_per_month_cte AS
  (select customer_id,
          month(txn_date) as txn_month,
          SUM(if(txn_type="deposit", 1, 0)) as deposit_count,
          SUM(if(txn_type="withdrawal", 1, 0)) as withdrawal_count,
          SUM(if(txn_type="purchase", 1, 0)) as purchase_count
   from customer_transactions
   group by customer_id,
            month(txn_date))
select txn_month,
       count(distinct customer_id) as customer_count
from transaction_count_per_month_cte
where deposit_count>1
  and (purchase_count = 1
       or withdrawal_count = 1)
group by txn_month;

-- What is the closing balance for each customer at the end of the month?

select
    customer_id,
    EXTRACT(year from txn_date) as year,
    EXTRACT(month from txn_date) as month,
    SUM(case 
        when txn_type = 'deposit' then txn_amount
        when txn_type = 'withdrawal' then -txn_amount
        else 0 
    end) as closing_balance
from customer_transactions
group by customer_id, year, month
order by customer_id, year, month;

-- What is the percentage of customers who increase their closing balance by more than 5%?

with CustomerBalances as (
  select
    customer_id,
    MIN(txn_date) as first_txn_date,
    MAX(txn_date) as last_txn_date
  from customer_transactions
  group by customer_id
), OpeningBalances as (
  select
    ct.customer_id,
    SUM(ct.txn_amount) as opening_balance
  from customer_transactions ct
  join CustomerBalances cb on ct.customer_id = cb.customer_id and ct.txn_date = cb.first_txn_date
  group by ct.customer_id
), ClosingBalances as (
  select
    ct.customer_id,
    SUM(ct.txn_amount) as closing_balance
  from customer_transactions ct
  join CustomerBalances cb on ct.customer_id = cb.customer_id and ct.txn_date = cb.last_txn_date
  group by ct.customer_id
), BalanceChanges as (
  select
    ob.customer_id,
    ob.opening_balance,
    cb.closing_balance,
    ((cb.closing_balance - ob.opening_balance) / ob.opening_balance) * 100 as balance_change_percent
  from OpeningBalances ob
  join ClosingBalances cb on ob.customer_id = cb.customer_id
)
select
  ROUND((select COUNT(*) from BalanceChanges where balance_change_percent > 5) * 100.0 / COUNT(*), 2) as percentage_customers_increased_more_than_5_percent
from BalanceChanges;
