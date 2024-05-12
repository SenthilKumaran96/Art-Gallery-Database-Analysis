use FamousPaintings
Select * from INFORMATION_SCHEMA.tables
Select top 10 * From artist where middle_names is not null
Select top 10 * From canvas_size 
Select top 10 * From image_link 
Select top 10 * From museum 
Select top 10 * From museum_hours
Select top 10 * From product_size
Select top 10 * From subject
Select top 10 * From work

--1. Fetch all the paintings which are not displayed on any museums?

Select * from work where museum_id is null;

--2. Are there museums without any paintings?

Select * from museum m where not exists (Select work_id from work w where w.museum_id = m.museum_id) ;

--3. How many paintings have an asking price of more than their regular price?
Select * from product_size where sale_price > regular_price

--4. Identify the paintings whose asking price is less than 50% of its regular price

Select * from product_size where sale_price < (0.5*regular_price);

--5. Which canva size costs the most?
--Solution 1:
Select top 1 cs.size_id, max(sale_price) Maximumcost From canvas_size cs
join product_size ps
on cs.size_id = ps.size_id
group by cs.size_id
order by Maximumcost desc
--Solution 2:
Select * from canvas_size cs
join(
Select *,rank() over(order by  sale_price desc) rn From product_size) ps
on ps.size_id = cs.size_id and ps.rn=1

--6. Delete duplicate records from work, product_size, subject and image_link tables
--product_size Table
Select work_id,size_id,sale_price,regular_price, Count(*) from product_size
--where work_id= 122224
group by work_id,size_id,sale_price,regular_price
having Count(*) > 1

with cte as(
Select *, row_number() over(partition by work_id,size_id,sale_price,regular_price order by work_id) duplicate_counts
from product_size  --where work_id= 122224
)
delete  from cte where duplicate_counts>1

--work Table
Select work_id,name,artist_id,style,museum_id, count(*) duplicate_Values from work
group by work_id,name,artist_id,style,museum_id
having Count(*) >1

with cte as (
Select *,ROW_NUMBER() over (partition by work_id,name,artist_id,style,museum_id order by work_id) duplicate_Values  
from work
)
delete from cte where duplicate_Values >1

--subject Table
Select work_id,subject, Count(*) from subject
group by work_id,subject
having Count(*) > 1

with cte as (
Select *,ROW_NUMBER() over (partition by work_id,subject order by work_id) duplicate_Values  
from subject
)
delete from cte where duplicate_Values >1

--image_link Table

Select work_id,url,thumbnail_small_url,thumbnail_large_url, Count(*) from image_link
group by work_id,url,thumbnail_small_url,thumbnail_large_url
having Count(*) > 1

with cte as (
Select *,ROW_NUMBER() over (partition by work_id,url,thumbnail_small_url,thumbnail_large_url order by work_id) duplicate_Values  
from image_link
)
delete from cte where duplicate_Values >1


--7. Identify the museums with invalid city information in the given dataset
Select distinct city  from museum
select * from museum 
	where city like '%[0-9]%'

--8. Museum_Hours table has 1 invalid entry. Identify it and remove it.

Select museum_id,day, Count(*) from museum_hours
group by museum_id,day
having Count(*) > 1

Select * from museum_hours where museum_id = 80

with cte as (
Select *,ROW_NUMBER() over (partition by museum_id,day order by museum_id) duplicate_Values  
from museum_hours
)
delete from cte where duplicate_Values >1

--9. Fetch the top 10 most famous painting subject

Select top 10 subject, count(*) Totcount from subject s
join work w
on s.work_id = w.work_id
group by subject
order by Totcount desc

select * 
	from (
		select s.subject,count(1) as no_of_paintings
		,rank() over(order by count(1) desc) as ranking
		from work w
		join subject s on s.work_id=w.work_id
		group by s.subject ) x
	where ranking <= 10;

--10. Identify the museums which are open on both Sunday and Monday. Display museum name, city.

Select mu.museum_id,mu.name from museum_hours m
join museum mu
on m.museum_id = mu.museum_id
where day = 'Sunday' and exists (Select museum_id from museum_hours n where n.museum_id = m.museum_id and n.day = 'Monday')

--11. How many museums are open every single day?
--Solution 1
Select Count(*) TotMuseumopen from (
Select m.museum_id, Count(*) Opendays from museum_hours mh
join museum m
on mh.museum_id = m.museum_id
Group by m.museum_id
having Count(*) = 7
) a

--12. Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)

Select top 5 m.museum_id,m.name, Count(*) [No Of Paintings] from museum m
join  work w
on m.museum_id = w.museum_id
group by m.museum_id,m.name
order by [No Of Paintings] desc

select m.name as museum, m.city,m.country,x.no_of_painintgs
	from (	select m.museum_id, count(1) as no_of_painintgs
			, rank() over(order by count(1) desc) as rnk
			from work w
			join museum m on m.museum_id=w.museum_id
			group by m.museum_id) x
	join museum m on m.museum_id=x.museum_id
	where x.rnk<=5;

--13. Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)

Select top 5 a.artist_id,a.full_name, Count(*) [Total no of Paintings] from artist a
join work w
on a.artist_id = w.artist_id
group by a.artist_id,a.full_name
order by [Total no of Paintings] desc

select a.full_name as artist, a.nationality,x.no_of_painintgs
	from (	select a.artist_id, count(1) as no_of_painintgs
			, rank() over(order by count(1) desc) as rnk
			from work w
			join artist a on a.artist_id=w.artist_id
			group by a.artist_id) x
	join artist a on a.artist_id=x.artist_id
	where x.rnk<=5;

--14. Display the 3 least popular canva sizes
Select * from (
Select cs.label, Count(*) TotalCount ,dense_rank () over( order by Count(*) ) rnk from product_size ps
join canvas_size cs
on cs.size_id = ps.size_id
join  work w
on w.work_id = ps.work_id
group by cs.label
--order by TotalCount
) a
where a.rnk <=3

--15. Which museum is open for the longest during a day. Dispay museum name, state and hours open and which day?
Select * from (
Select m.museum_id, datediff(hh,[Open],[Close]) [Open Hours],mh.day,m.name,dense_rank() over(order by datediff(hh,[Open],[Close]) desc) rn
from Museum_Hours mh
join museum m
on mh.museum_id = m.museum_id
group by m.museum_id,datediff(hh,[Open],[Close]),mh.day,m.name
) a
where a.rn = 1
--Validating the Query
Select datediff(hh,[Open],[Close]) [Open Hours], * from museum_hours
order by [Open Hours] desc

--16. Which museum has the most no of most popular painting style?
with pop_style as 
			(select style
			,rank() over(order by count(1) desc) as rnk
			from work
			group by style),
		cte as
			(select w.museum_id,m.name as museum_name,ps.style, count(1) as no_of_paintings
			,rank() over(order by count(1) desc) as rnk
			from work w
			join museum m on m.museum_id=w.museum_id
			join pop_style ps on ps.style = w.style
			where w.museum_id is not null
			and ps.rnk=1
			group by w.museum_id, m.name,ps.style)
	select museum_name,style,no_of_paintings
	from cte 
	where rnk=1;
--Solution 2
drop table if exists #temp
Select Style, Rank () over (order by Count(*) desc) rn  into #temp from work
group by Style

Select  m.museum_id,m.name,a.style, Count(*) [Total Paintings], rank() over(order by Count(*) desc) rnk  from museum m
join work w
on m.museum_id = w.museum_id
join #temp a
on w.style = a.style
where a.rn = 1
group by m.museum_id,m.name,a.style;


--17. Identify the artists whose paintings are displayed in multiple countries
with cte1 as (
Select distinct a.full_name [Artistname],--w.name [Paintingname],m.name,
m.country from work w
join museum m
on w.museum_id = m.museum_id
join artist a
on a.artist_id = w.artist_id
)
Select [Artistname], count(*) [No of Countries] from cte1
group by [Artistname]
having Count(*) > 1
order by 2 desc

--18. Display the country and the city with most no of museums. Output 2 seperate columns to mention the city and country. 
--If there are multiple value, seperate them with comma.
with Cte_Country as (
Select Country, Count(*) [No of Museum],rank () over(order by Count(*) desc) rnk from museum
group by Country
) ,
Cte_City as (
Select city, Count(*) [No of Museum],rank () over(order by Count(*) desc) rnk from museum
group by city
)

Select Distinct cc.country Country, STRING_AGG(cb.city,',') City from Cte_Country cc
cross join Cte_City cb
where cc.rnk = 1 and cb.rnk = 1
group by cc.country;

--19. Identify the artist and the museum where the most expensive and least expensive painting is placed. Display the artist name, 
--sale_price, painting name, museum name, museum city and canvas label
with cte as(
Select dense_RANK() over(order by sale_price desc) rnexpen,
dense_RANK() over(order by sale_price ) rncheap,*
from product_size
)
Select a.full_name [Artist Name],c.sale_price,w.name [Painting Name],m.name [Museum Name],m.city,cs.label from  cte c
join work w
on c.work_id = w.work_id
join museum m
on m.museum_id = w.museum_id
join artist a
on a.artist_id = w.artist_id
join canvas_size cs
on cs.size_id = c.size_id
where c.rnexpen = 1 or c.rncheap = 1;

--20. Which country has the 5th highest no of paintings?
Select * from (
Select m.country,Count(*) TotalCount,DENSE_RANK() over(order by Count(*) desc) Ranks from museum m
join work w
on m.museum_id = w.museum_id
group by m.country
) a
where a.Ranks = 5;

--21. Which are the 3 most popular and 3 least popular painting styles?
with cte as (
Select style, Count(*) Totcount,DENSE_RANK() over(order by Count(*) desc) mpop ,
DENSE_RANK() over(order by Count(*) ) lpop 
from work
where style is not null
group by style
--order by Count(*) desc
)
Select style, case when mpop <=3 then 'Most Popular' else 'Least Popular' end as Result  from cte 
where mpop <=3 or lpop <=3;

--22. Which artist has the most no of Portraits paintings outside USA?. Display artistname, no of paintings and the artist nationality.
Select * from (
select top 10 a.full_name [Artist Name],a.nationality, Count(*) [Total paintings],
DENSE_RANK() over(order by Count(*) desc) rnk
from museum m
join work w
on m.museum_id = w.museum_id
join subject s
on s.work_id = w.work_id
join artist a
on a.artist_id =w.artist_id
where m.country <> 'USA' and s.subject = 'Portraits'
group by a.full_name,a.nationality
) a
where a.rnk = 1




 









