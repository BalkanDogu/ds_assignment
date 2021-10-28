
CREATE DATABASE Actions

use Actions
CREATE TABLE Actions (Visitor_ID numeric(5,0), Adv_Type char(5), Action char(20))

use Actions
insert into Actions values (1, 'A', 'Left')
insert into Actions values (2, 'A', 'Order')
insert into Actions values (3, 'B', 'Left')
insert into Actions values (4, 'A', 'Order')
insert into Actions values (5, 'A', 'Review')
insert into Actions values (6, 'A', 'Left')
insert into Actions values (7, 'B', 'Left')
insert into Actions values (8, 'B', 'Order')
insert into Actions values (9, 'B', 'Review')
insert into Actions values (10, 'A', 'Review')

select *
from Actions

WITH T1 AS
		(
		select Adv_Type, COUNT(Action) X
		from Actions
		where Action = 'Order'
		GROUP BY Adv_Type),
T2 AS
		(
		SELECT Adv_Type, count(Adv_Type) Y
		FROM Actions
		GROUP BY Adv_Type)
SELECT T1.Adv_type, round((cast(T1.X AS FLOAT) / cast(T2.Y AS FLOAT)),2)  AS Conversion_Rate
FROM T1,T2
WHERE T1.Adv_Type = T2.Adv_Type;

