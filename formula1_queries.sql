use formula1;


-- top point scorers

select r.driver_id as id, d.driver_ref as driver, sum(points) as points_total
from results as r
inner join drivers as d
	on r.driver_id = d.driver_id
group by id, driver
order by points_total desc;


-- driver rankings by race wins and podiums

select a.driver, b.wins, c.podiums
from 
	(select driver_ref as driver, driver_id
	from drivers) as a
inner join 
	(select driver_id as driver, count(*) as wins
	from results
		where finish_position = 1
		group by driver_id) as b
			on a.driver_id = b.driver
inner join
	(select driver_id as driver, count(*) as podiums
	from results
	where finish_position between 1 and 3
	group by driver_id) as c
		on b.driver = c.driver
order by wins desc;


-- ranking nationalities by number of wins and podiums

select distinct d.nationality as nationality, wins, podiums
from drivers as d
inner join
	(select d.nationality, count(*) as wins
	from results as r
	inner join drivers as d
		on d.driver_id = r.driver_id
	where r.finish_position = 1
	group by d.nationality) as a
		on d.nationality = a.nationality
inner join
	(select d.nationality, count(*) as podiums
	from results as r
	inner join drivers as d
		on d.driver_id = r.driver_id
		where r.finish_position between 1 and 3
	group by d.nationality) as b
		on a.nationality = b.nationality
order by wins desc;


-- find the most common failure statuses during races

select sub.status_id as id, s.status as status, instances
from status as s
inner join
	(select status_id, count(*) as instances
	from results
	group by 1) as sub
		on sub.status_id = s.status_id
where status not regexp '[+]|finished'
	and status not like '%qualify%'
order by instances desc;


-- number of drivers by nationality

select nationality, count(*) as total_drivers
from drivers
group by nationality
order by 2 desc;


-- drivers that have completed the most laps

select r.driver_id as id, d.driver_ref as driver, sum(laps) as laps
from results as r
	inner join drivers as d
		on r.driver_id = d.driver_id
group by 1,2
order by laps desc;


-- percentage of total laps in f1 that Alonso has raced

select distinct r.driver_id as id, d.driver_ref as driver,
	(select sum(laps)
	from results as r
	where driver_id = 4) 
    / 
    (select sum(laps)
	from results) * 100 as alonso_laps_pct
from results as r
	inner join drivers as d
		on r.driver_id = d.driver_id
where r.driver_id = 4;


-- percentage of races that Alonso has raced

select distinct r.driver_id as id, d.driver_ref as driver,
	(select count(race_id)
	from results
	where driver_id = 4) 
    / 
    (select count(distinct race_id)
	from results) * 100 as alonso_races_pct
from results as r
	inner join drivers as d
		on r.driver_id = d.driver_id
where r.driver_id = 4;


-- drivers that finished in our out of the points

select r.driver_id as id, r.points, d.driver_ref as driver,
	case when
		finish_position between 1 and 10 then 'yes'
        else 'no' end as points_won
from results as r
inner join drivers as d
	on r.driver_id = d.driver_id;


-- find drivers that started outside the top 10 and won the race

select r.driver_id as id, d.driver_ref as driver, r.start_position as start, r.finish_position as finish
from results as r
	inner join drivers as d
		on r.driver_id = d.driver_id
where 
	start_position > 10 
    and finish_position = 1
order by start desc;


-- circuits where max verstappen has won

select distinct races.name as circuit_name
from results
	inner join races
		on results.race_id = races.race_id
where finish_position = 1
	and driver_id = 830;


-- count number of different circuits that max verstappen has won at (using a cte)

with circuits as
(
select distinct races.name
from results
	inner join races
		on results.race_id = races.race_id
where finish_position = 1
	and driver_id = 830)

select count(*) as number_of_circuits
from circuits;


-- number of circuits by country

select country, count(*) as number_of_circuits
from circuits
group by country;


-- circuits where the most number of races have occurred

select c.name as circuit, count(*) as number_of_races
from races as r
	inner join circuits as c
		on r.circuit_id = c.circuit_id
group by c.circuit_id
order by number_of_races desc;


-- ranking drivers by avg finish using a cte

with c as 
(
select *
from results
where finish_position <> 0
)

select distinct c.driver_id, d.driver_ref, round(avg(c.finish_position),2) as avg_finish 
from c
	inner join drivers as d
		on c.driver_id = d.driver_id
group by 1, 2
order by avg_finish;


-- partition showing all race results as well as avg finish for each driver

select race_id as race, driver_id as id, finish_position as finish, 
		avg(finish_position) over(partition by driver_id) as avg_finish
from results
where finish_position <> 0
order by race_id desc, finish asc;


-- cte (with group by) and inner joins to show the 2022 Miami Grand Prix stats

with tmp as
(
select driver_id, round(avg(finish_position),1) as avg_finish
from results
	where finish_position <> 0
group by driver_id
)

select races.name, races.date, r.driver_id as id, r.finish_position as finish, d.driver_ref as driver, tmp.avg_finish
from results as r
	inner join drivers as d
		on r.driver_id = d.driver_id
	inner join races
		on races.race_id = r.race_id
	inner join tmp
		on tmp.driver_id = r.driver_id
where r.race_id = 1078;


-- same result as above using a partition and subquery in the from statement

select *
from
	(select r.race_id as race, races.name, races.date, r.driver_id as id, d.driver_ref as driver, r.finish_position as finish, 
			avg(r.finish_position) over(partition by r.driver_id) as avg_finish
	from results as r
		inner join drivers as d
			on r.driver_id = d.driver_id
		inner join races
			on r.race_id = races.race_id
	where finish_position <> 0
	order by r.race_id desc, finish asc) as tmp
where race = 1078;


-- number of pit stops (strategy) that works best for each circuit the past 12 seasons

with stops as
(
select r.race_id, r.driver_id, max(p.stop) as stops
from results as r
	inner join pit_stops as p
		on r.race_id = p.race_id
where finish_position = 1
group by 1, 2
)

select r.race_id, races.date, races.name as grand_prix, d.driver_ref as winner, r.finish_position as finish, s.stops
from results as r
	inner join races
		on r.race_id = races.race_id
	inner join drivers as d
		on r.driver_id = d.driver_id
	inner join stops as s
		on r.race_id = s.race_id
where r.finish_position = 1;


-- window functions: row_number(), rank(), dense_rank(), lead(), lag(), over(partition by...order by...)
-- using row_number() and then making it a subquery to extract rows

select * from 
	(select a.driver, b.wins, c.podiums, 
			row_number() over(order by wins desc) as rn
	from 
		(select driver_ref as driver, driver_id
		from drivers) as a
	inner join 
		(select driver_id as driver, count(*) as wins
		from results
			where finish_position = 1
			group by driver_id) as b
				on a.driver_id = b.driver
	inner join
		(select driver_id as driver, count(*) as podiums
		from results
		where finish_position between 1 and 3
		group by driver_id) as c
			on b.driver = c.driver
	order by wins desc) as tmp
where tmp.rn < 11;


-- rank() used to rank drivers by wins against their fellow countrymen

select nationality, driver_ref, tmp.wins,
		rank() over(partition by nationality order by wins desc) as rankings
from drivers as d
	inner join 
		(select driver_id, count(*) as wins
        from results
        where finish_position = 1
        group by driver_id) as tmp
        on d.driver_id = tmp.driver_id
	order by nationality; 

-- lag(x, y, z) showing if verstappen's pit times improved at the dutch GP

select  p.race_id, r.name, p.driver_id, d.driver_ref as driver, p.duration as pit_time,
		lag(p.duration) over() as prev_pit,
	case when p.duration < lag(p.duration) over() then 'faster'
    else 'slower' end as compared
from pit_stops as p
	inner join races as r
		on p.race_id = r.race_id
	inner join drivers as d
		on p.driver_id = d.driver_id
where p.race_id = 1088
	and d.driver_id = 830;


-- running total of drivers' points throughout the 2022 season (no sprint races)

select ra.round, ra.name as grand_prix, ra.date, r.race_id, r.driver_id, d.driver_ref as driver, 
		r.start_position as start, r.finish_position as finish, r.points,
		sum(points) over(partition by r.driver_id order by ra.round, r.finish_position) as points_total
from results as r
	inner join races as ra
		on r.race_id = ra.race_id
	inner join drivers as d
		on r.driver_id = d.driver_id
where ra.date like '%2022%'
	and r.finish_position <> 0
order by round, finish;


-- use paging ntile(n) --> splits drivers into 10 pages ranked by laps raced (finds drivers in each 10nth percentile)

select r.driver_id as id, d.driver_ref as driver, sum(laps) as laps,
		ntile(10) over(order by sum(laps) desc) as tenths
from results as r
	inner join drivers as d
		on r.driver_id = d.driver_id
group by 1,2
order by laps desc;


-- using above to group and find average of each percentile

 with l as 
(
select r.driver_id as id, d.driver_ref as driver, sum(laps) as laps,
		ntile(10) over(order by sum(laps) desc) as tenths
from results as r
	inner join drivers as d
		on r.driver_id = d.driver_id
group by 1,2
order by laps desc
)

select l.tenths, round(avg(laps),2)
from l
group by l.tenths;


-- running sum() max() min() avg() for verstappen points in 2022 season

select ra.round, ra.name as grand_prix, ra.date, r.race_id, r.driver_id, d.driver_ref as driver, 
		r.start_position as start, r.finish_position as finish, r.points,
        sum(points) over(order by round) as total,
        max(points) over(order by round) as max,
        min(points) over(order by round) as min,
        avg(points) over(order by round) as avg_points
from results as r
	inner join races as ra
		on r.race_id = ra.race_id
	inner join drivers as d
		on r.driver_id = d.driver_id
where ra.date like '%2022%'
	and r.finish_position <> 0
    and r.driver_id = 830
order by round, finish;


-- sprint races running points total for the 2022 season

select race_id, driver_id, start_position, finish_position, points,
		sum(points) over(partition by driver_id order by race_id, finish_position) as sprint_points
from sprint_results
where race_id between 1074 and 1096
	and finish_position <> 0
order by race_id, finish_position;


-- wins of drivers with win subtotals by nationality and win grandtotal

select d.nationality, d.driver_ref as driver, count(r.driver_id) as wins
from drivers as d
	inner join 
    (select driver_id
    from results
    where finish_position = 1) as r
		on r.driver_id = d.driver_id
group by 1, 2 with rollup
order by nationality desc;


-- use coalesce(x,y) to replace null values with totals

select coalesce(d.nationality, 'total_wins'), coalesce(d.driver_ref, 'total') as driver, count(r.driver_id) as wins
from drivers as d
	inner join 
    (select driver_id
    from results
    where finish_position = 1) as r
		on r.driver_id = d.driver_id
group by 1, 2 with rollup
order by 1 desc;


-- group_concat and separator used to list drivers from countries more cleanly

select nationality, group_concat(driver_ref separator ', ') as driver
from drivers
group by nationality
order by nationality desc;

