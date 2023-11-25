--1. Вывести к каждому самолету класс обслуживания и количество мест этого класса
SELECT ad.model, s.fare_conditions, COUNT(s.seat_no) 
FROM seats s  
	JOIN aircrafts_data ad  
	ON s.aircraft_code = ad.aircraft_code
GROUP BY ad.model, s.fare_conditions
ORDER BY ad.model


--2. Найти 3 самых вместительных самолета (модель + кол-во мест)
SELECT ad.model, COUNT(s.seat_no) as count_seats
FROM seats s 
	JOIN aircrafts_data ad 
	ON s.aircraft_code = ad.aircraft_code
GROUP BY ad.model
ORDER BY count_seats DESC
LIMIT 3

--3 Найти все рейсы, которые задерживались более 2 часов
select *
from flights f 
where actual_arrival - scheduled_arrival > interval '2 hour' and status = 'Arrived' 

--4 Найти последние 10 билетов, купленные в бизнес-классе (fare_conditions = 'Business'), с указанием имени пассажира и контактных данных
select t.passenger_name, t.contact_data
from ticket_flights tf 
	join tickets t 
		on tf.ticket_no = t.ticket_no
		join bookings b  
			on b.book_ref = t.book_ref
where fare_conditions = 'Business'
group by t.passenger_name, t.contact_data, b.book_date
order by b.book_date desc
limit 10

--5 Найти все рейсы, у которых нет забронированных мест в бизнес-классе (fare_conditions = 'Business')
select f.*
from flights f
	right join ticket_flights tf 
	on tf.flight_id = f.flight_id  
where f.flight_id in (select flight_id
					  from ticket_flights tf  
					  where fare_conditions = 'Business'
					  group by flight_id
					  having count(ticket_no) = 0)
group by f.flight_id

--6 Получить список аэропортов (airport_name) и городов (city), в которых есть рейсы с задержкой
select a.airport_name, a.city
from airports a 
	join flights f 
		on a.airport_code = f.departure_airport 
where f.status = 'Delayed'
group by a.airport_name, a.city 

--7 Получить список аэропортов (airport_name) и количество рейсов, вылетающих из каждого аэропорта, отсортированный по убыванию количества рейсов
select a.airport_name, count(f.flight_no) count_flight 
from airports a 
	join flights f 
		on a.airport_code = f.departure_airport 
group by a.airport_name
order by count_flight desc

--8 Найти все рейсы, у которых запланированное время прибытия (scheduled_arrival) 
--было изменено и новое время прибытия (actual_arrival) не совпадает с запланированным
select * 
from flights f 
where f.scheduled_arrival != f.actual_arrival 
order by f.flight_no 

--9 Вывести код, модель самолета и места не эконом класса для самолета "Аэробус A321-200" с сортировкой по местам
--вариант с готовым представлением
select a.aircraft_code, a.model, s.seat_no
from aircrafts a 
	join seats s 
		on s.aircraft_code = a.aircraft_code
where s.fare_conditions != 'Economy' and a.model != 'Аэробус A321-200'
order by s.seat_no 
--вариант без представления
select ad.aircraft_code, ad.model, s.seat_no
from aircrafts_data ad  
	join seats s 
		on s.aircraft_code = ad.aircraft_code 
where s.fare_conditions != 'Economy' and ad.model ->> 'ru' > 'Аэробус A321-200'
order by s.seat_no 

--10 Вывести города, в которых больше 1 аэропорта (код аэропорта, аэропорт, город)
select airport_code, airport_name, city
from airports a
where a.city in (select city as c
				from airports 
				group by city 
				having count(airport_code) > 1)

--11 Найти пассажиров, у которых суммарная стоимость бронирований превышает среднюю сумму всех бронирований
select t.passenger_name
from tickets t 
	left join bookings b 
	on t.book_ref = b.book_ref 
group by t.passenger_name 
having sum(b.total_amount) > (select avg(total_amount)
								from bookings)

--12 Найти ближайший вылетающий рейс из Екатеринбурга в Москву, на который еще не завершилась регистрация
select *
from flights_v fv 
where fv.departure_city = 'Екатеринбург' and fv.arrival_city = 'Москва' 
	and status in ('On Time', 'Scheduled', 'Delayed')
order by fv.scheduled_departure_local desc
limit 1

--13 Вывести самый дешевый и дорогой билет и стоимость (в одном результирующем ответе)
-- вывод только стоимостей
select min(tf.amount) as min, max(tf.amount) as max 
from ticket_flights tf 

--вывод всех билетов максимальной и минимальной стоимостей
select tf.ticket_no as "номер билета", tf.amount as "стоимость" 
from ticket_flights tf
where tf.amount in (
	(select min(tf.amount) 
	from ticket_flights tf),
	(select max(tf.amount)
	from ticket_flights tf))
order by tf.amount desc

--вывод по одному билету
select tf.ticket_no as "номер билета", tf.amount as "стоимость" 
from ticket_flights tf
where tf.ticket_no in (
	(select tf1.ticket_no
	from ticket_flights tf1
	group by tf1.ticket_no, tf1.amount
	order by tf1.amount 
	limit 1
	),
	(select tf1.ticket_no
	from ticket_flights tf1
	group by tf1.ticket_no, tf1.amount
	order by tf1.amount desc 
	limit 1
	))
and tf.amount in (
	(select min(tf.amount) 
	from ticket_flights tf),
	(select max(tf.amount)
	from ticket_flights tf))
order by tf.amount desc

--вывод по одному билету union 
(select tf.ticket_no, tf.amount
from ticket_flights tf
where tf.amount =(
	(select min(tf.amount) 
	from ticket_flights tf))
order by tf.amount desc
limit 1)
union 
(select tf.ticket_no, tf.amount
from ticket_flights tf
where tf.amount =(
	(select max(tf.amount) 
	from ticket_flights tf))
order by tf.amount desc
limit 1)

--14 Написать DDL таблицы Customers, должны быть поля id, first_name, last_name, email, phone. Добавить ограничения на поля (constraints)
create table bookings.customers (
	id uuid not null PRIMARY KEY DEFAULT gen_random_uuid() , 
	first_name varchar(30) not null, 
	last_name varchar(30) not null, 
	email varchar(30) check(length(email) > 5), 
	phone varchar(20) check(length(phone) >= 7)
)

--15 Написать DDL таблицы Orders, должен быть id, customer_id, quantity. Должен быть внешний ключ на таблицу customers + constraints
create table bookings.orders (
	id uuid not null PRIMARY key DEFAULT gen_random_uuid() , 
	customer_id uuid not null, 
	quantity bigint check(quantity > 0),
	FOREIGN KEY (customer_id) REFERENCES bookings.customers(id) on delete cascade
)

--16 Написать 5 insert в эти таблицы
insert into customers(first_name, last_name, email, phone)
values ('Elena', 'Kechko', 'ekechko@gmail.com', '+375-29-179-81-96'),
	   ('Anna', 'Ivanova', 'ivanovaa@gmail.com', '+375-29-111-11-11')

insert into customers(first_name, last_name, email)
values ('Sasha', 'Popov', 'popovsas@gmail.com')

insert into customers(first_name, last_name, phone)
values ('Oleg', 'Karp', '+375-29-222-22-22')

insert into customers(first_name, last_name)
values ('Dima', 'Ivanov')


insert into orders (customer_id, quantity)
select id, 3 from customers where last_name = 'Kechko' and first_name = 'Elena'

insert into orders (customer_id, quantity)
select id, 2 from customers where last_name = 'Kechko' and first_name = 'Elena'

insert into orders (customer_id, quantity)
select id, 100 from customers where last_name = 'Ivanova' and first_name = 'Anna'

insert into orders (customer_id, quantity)
select id, 15 from customers where last_name = 'Ivanov' and first_name = 'Dima'

insert into orders (customer_id, quantity)
select id, 1 from customers where last_name = 'Popov'  and first_name = 'Sasha'

--17 Удалить таблицы
Drop table if EXISTS bookings.orders
Drop table if exists bookings.customers
