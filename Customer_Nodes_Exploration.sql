-- Customer_Nodes Exploration

-- How many unique nodes are there on the Data Bank system?

select count(distinct node_id) from customer_nodes;

-- What is the number of nodes per region?

select region_id,  count(node_id) as num_nodes
from customer_nodes
group by region_id
order by region_id;

-- How many customers are allocated to each region?

select region_id, count(distinct(customer_id)) as num_customer
from customer_nodes
group by region_id
order by region_id;

-- How many days on average are customers reallocated to a different node?

select round(avg(datediff(end_date, start_date)),0) as "Average No. Reallocation of Days" from customer_nodes;

-- What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

with reallocation as
  (select *,
          (datediff(end_date, start_date)) as reallocation_days
from customer_nodes
inner join regions using (region_id)),
 percentile as

(select *, percent_rank() over(partition by region_id order by reallocation_days)*100 as pct
  from reallocation)
select region_id, region_name, reallocation_days
from percentile_cte
where pct >95
group by region_id, region_name, reallocation_days;
