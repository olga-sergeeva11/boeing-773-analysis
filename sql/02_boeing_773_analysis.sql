with flight_class_stats as (select tf.flight_id,
tf.fare_conditions,
count(tf.ticket_no) as tickets_cnt,
min(tf.amount) as min_ticket_price
from ticket_flights tf
join flights f
on tf.flight_id=f.flight_id
where f.aircraft_code = '773'
and f.status = 'Arrived'
group by 1,2),

-- Вместимость Boeing 773 в данных: 402 места
-- Economy — 324, Comfort — 48, Business — 30
	
-- Для оценки потенциально упущенной выручки используется минимальная
-- фактическая цена проданного билета соответствующего класса на рейсе.
-- Такой подход выбран как консервативный, чтобы не завышать оценку.
lost_revenue_by_class as (select flight_id,
sum(
case
	when fare_conditions = 'Economy'
	then (324-tickets_cnt) * min_ticket_price
	else 0
	end) as economy_lost,
sum(
case
	when fare_conditions = 'Comfort'
	then (48-tickets_cnt) * min_ticket_price
	else 0
	end) as comfort_lost,
sum(
case
	when fare_conditions = 'Business'
	then (30-tickets_cnt) * min_ticket_price
	else 0
	end) as business_lost
from flight_class_stats
group by 1),

flight_metrics as (select f.flight_id,
ad1.city->>'ru' as departure_city,
ad2.city->>'ru' as arrival_city,
f.scheduled_departure as flight_date,
sum(tf.amount) as actual_revenue,
count(tf.ticket_no) as passengers_cnt,

-- Загрузка рейса: количество проданных билетов / 402 места
round(count(tf.ticket_no)/402.0*100,2) as load_pct

from flights as f
join airports_data ad1
on f.departure_airport=ad1.airport_code
join airports_data ad2
on f.arrival_airport=ad2.airport_code
join ticket_flights as tf
on f.flight_id=tf.flight_id
where f.aircraft_code = '773'
and f.status = 'Arrived'
group by 1,2,3,4),

flight_analysis as (select lrc.flight_id,
fm.departure_city,
fm.arrival_city,
fm.flight_date,
lrc.economy_lost,
lrc.comfort_lost,
lrc.business_lost,
fm.actual_revenue,

-- Суммарная оценка потенциально упущенной выручки
-- по Economy, Comfort и Business на конкретном рейсе.
-- Если по классу не было продаж, его вклад в денежную оценку равен 0,
-- так как фактическая цена этого класса на рейсе отсутствует.
lrc.economy_lost
+ lrc.comfort_lost
+ lrc.business_lost as lost_total,

-- Доля потенциально упущенной выручки
-- в потенциальной выручке рейса
round((lrc.economy_lost + lrc.comfort_lost + lrc.business_lost)/
(fm.actual_revenue + lrc.economy_lost + lrc.comfort_lost + lrc.business_lost)
* 100,2) as lost_share_pct,

fm.passengers_cnt,	
fm.load_pct
from lost_revenue_by_class lrc
join flight_metrics fm
on lrc.flight_id = fm.flight_id)

select flight_id,
departure_city,
arrival_city,
flight_date,
economy_lost,
comfort_lost,
business_lost,
actual_revenue,
lost_total,
lost_share_pct,
passengers_cnt,
load_pct
from flight_analysis
order by lost_share_pct desc;
