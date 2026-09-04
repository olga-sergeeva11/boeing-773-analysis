-- Характеристики самолётов

SELECT aircraft_code, model, range
from aircrafts_data
order by 3 desc
--


-- Вместимость самолетов

select s.aircraft_code, count(s.seat_no)
from seats s
group by 1
order by 2
--


-- Выручка и средняя выручка на рейс по типу самолёта

select f.aircraft_code,
       sum(tf.amount),
       round(sum(tf.amount) / count(distinct f.flight_id), 2)
from flights f
left join ticket_flights tf on f.flight_id = tf.flight_id
where f.status = 'Arrived'
group by 1
order by 3 desc
--


-- Самые низкозагруженные рейсы 773
select f.flight_id, count(tf.ticket_no), round(count(tf.ticket_no)/402.0*100,2) as proc_zap
from flights f
left join ticket_flights tf on f.flight_id=tf.flight_id
where f.status = 'Arrived' and f.aircraft_code = '773'
group by 1
order by 3
limit 5
--


-- Самые низкозагруженные рейсы 773 + маршруты

select f.flight_id, ad2.city->>'ru' as город_отправления, ad3.city->>'ru' as город_прибытия,
round(count(tf.ticket_no)/402.0*100,2) as proc_zap
from flights f
left join ticket_flights tf on f.flight_id=tf.flight_id
left join airports_data ad2 on f.departure_airport=ad2.airport_code
left join airports_data ad3 on f.arrival_airport = ad3.airport_code
where f.status = 'Arrived' and f.aircraft_code = '773'
group by 1,2,3
order by 4
limit 5
--


-- Вместимость 773 по классам
select aircraft_code, count (seat_no), fare_conditions
from seats s
where s.aircraft_code = '773'
group by 1,3
--


-- Период доступных данных по 773
select MIN(scheduled_departure) min_date, MAX(scheduled_departure) max_date, COUNT(DISTINCT flight_id)
from flights f
where aircraft_code = '773' and status = 'Arrived'
--