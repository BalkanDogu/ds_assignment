

create database Transaction1
use Transaction1
create table Transaction1 (Sender_ID numeric(5,0), Receiver_ID numeric(5,0), Amount numeric(5,0), Transaction_ID DATE)
select *
from Transaction1

use Transaction1
insert into Transaction1 (Sender_ID, Receiver_ID, Amount, Transaction_ID ) values (55, 22, 500, '2021-05-18')
insert into Transaction1 (Sender_ID, Receiver_ID, Amount, Transaction_ID ) values (11, 33, 350, '2021-05-19')
insert into Transaction1 (Sender_ID, Receiver_ID, Amount, Transaction_ID ) values (22, 11, 650, '2021-05-19')
insert into Transaction1 (Sender_ID, Receiver_ID, Amount, Transaction_ID ) values (22, 33, 900, '2021-05-20')
insert into Transaction1 (Sender_ID, Receiver_ID, Amount, Transaction_ID ) values (33, 11, 500, '2021-05-21')
insert into Transaction1 (Sender_ID, Receiver_ID, Amount, Transaction_ID ) values (33, 22, 750, '2021-05-21')
insert into Transaction1 (Sender_ID, Receiver_ID, Amount, Transaction_ID ) values (11, 44, 300, '2021-05-22')

select *
from Transaction1


select Sender_ID, sum(Amount) Top_gon
From Transaction1
group by Sender_ID

select Receiver_ID, sum(Amount) Top_al
From Transaction1
group by Receiver_ID


SELECT	COALESCE(A.Sender_ID, B.Receiver_ID) AS Account_ID,
		COALESCE(B.Top_al, 0) - COALESCE(A.Top_gon, 0) AS Net_Change

from	(select Sender_ID, sum(Amount) Top_gon
		From Transaction1
		group by Sender_ID) A
full join	(select Receiver_ID, sum(Amount) Top_al
			From Transaction1
			group by Receiver_ID) B ON A.Sender_ID = B.Receiver_ID



