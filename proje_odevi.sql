

--- SQL PROJE ODEVI 

-- not 1 : format de�i�ikli�i yap�p dosyalar� y�klemek iki g�n s�rd� yani �deve ba�lama s�resi iki g�n 

-- not 2 : hocam ben sizin bu sql dosyan�z� g�rmedim odevi yaparken bitirmek �zereyken farkettim o 
-- o y�zden sizin �unu kullan�n bunu kullan�n dedi�iniz �eylerle yap�lmam�� olabilir sorular ama 
-- bu benim du�unup bulmam i�in daha iyi oldu.

/* T�m tablolara kat�l�n ve t�m s�tunlarla birle�tirilmi�_tablo ad� verilen yeni bir tablo olu�turun. 
(market_fact, cust_dimen, order_dimen, prod_dimen, shipping_dimen) */


DROP TABLE IF EXISTS combined_table

SELECT * INTO combined_table
FROM(SELECT A.Cust_id, A.Discount, A.Ord_id,A.Order_Quantity,A.Prod_id,A.Product_Base_Margin,A.Sales,A.Ship_id,
			B.Customer_Name,B.Customer_Segment,B.Province,B.Region,
			C.Order_Date,C.Order_Priority,
			D.Product_Category,D.Product_Sub_Category,
			E.Ship_Date,E.Ship_Mode,E.Order_ID
	 FROM dbo.market_fact A
			INNER JOIN dbo.cust_dimen B ON A.Cust_id = B.Cust_id
			INNER JOIN dbo.orders_dimen C ON A.Ord_id = C.Ord_id
			INNER JOIN dbo.prod_dimen D ON A.Prod_id = D.Prod_id
			INNER JOIN dbo.shipping_dimen E ON A.Ship_id = E.Ship_id) A



-- Result of Q-2:
-- Maksimum sipari� say�s�na sahip ilk 3 m��teriyi bulun.

SELECT TOP 3 Cust_id, COUNT(ord_id) count_of_orders
FROM market_fact
GROUP BY Cust_id
ORDER BY COUNT(ord_id) DESC


-- Result of Q-3:
--Kombine_tabloda, Sipari�_Tarihi ve Sevk_Tarihi aras�ndaki tarih fark�n� i�eren DaysTakenForDelivery 
--olarak yeni bir s�tun olu�turun.

ALTER TABLE dbo.combined_table
ADD DaysTakenForDelivery int;

UPDATE dbo.combined_table
SET DaysTakenForDelivery = DATEDIFF(DAY, Order_Date, Ship_Date);

SELECT *
FROM dbo.combined_table

-- Result of Q-4:

--Sipari�inin teslim edilmesi i�in maksimum s�reyi alan m��teriyi bulun.

SELECT TOP 1 Cust_id, Customer_Name,Order_Date,Ship_Date, DaysTakenForDelivery
FROM dbo.combined_table
ORDER BY DaysTakenForDelivery DESC

-- Result of Q-5:
--Ocak ay�ndaki toplam benzersiz m��teri say�s�n� ve 2011'de t�m y�l boyunca ka� tanesinin 
--her ay geri geldi�ini say�n.

SELECT MONTH(A.Order_Date) MONTH, COUNT(DISTINCT B.Cust_id)MOUNTHLY_NUM_OF_CUST
FROM orders_dimen A, market_fact B
WHERE A.Ord_id = B.Ord_id
AND YEAR(Order_Date) = 2011
AND B.Cust_id IN(
					SELECT B.Cust_id
					FROM orders_dimen A, market_fact B
					WHERE A.Ord_id = B.Ord_id
					AND MONTH(Order_Date) = 1
					AND YEAR(Order_Date) = 2011
					GROUP BY B.Cust_id)
GROUP BY MONTH(A.Order_Date)


-- Result of Q-6:
-- Her kullan�c� i�in ilk sat�n alma ile ���nc� sat�n alma aras�nda ge�en s�reyi M��teri Kimli�ine g�re 
-- artan s�rada d�nd�recek bir sorgu yaz�n.


WITH T1 AS(
SELECT Cust_id, Order_Date,
DENSE_RANK() OVER(PARTITION BY Cust_id ORDER BY Order_Date) DENSE_NUMBER,
MIN(Order_Date) OVER(PARTITION BY Cust_id ORDER BY Order_Date) FIRST_ORDER_DATE
FROM combined_table)

SELECT DISTINCT Cust_id, Order_Date, DENSE_NUMBER, FIRST_ORDER_DATE,
DATEDIFF(DAY, FIRST_ORDER_DATE, Order_Date)DAYS_ELAPSED
FROM T1
WHERE dense_number = 3
ORDER BY Cust_id ASC


-- Result of Q-7:
--Hem 11. �r�n� hem de 14. �r�n� sat�n alan m��terileri ve bu �r�nlerin m��teri taraf�ndan sat�n al�nan 
--toplam �r�n say�s�na oran�n� veren bir sorgu yaz�n.

WITH T1 AS(
SELECT Cust_id,
	SUM(CASE WHEN Prod_id = 'Prod_11' THEN 1*Order_Quantity ELSE 0 END)P11,
	SUM(CASE WHEN Prod_id = 'Prod_14' THEN 1*Order_Quantity ELSE 0 END)P14,
	SUM(CASE WHEN Prod_id IS NOT NULL THEN 1*Order_Quantity ELSE 0 END)TOTAL_PROD
FROM dbo.combined_table
GROUP BY Cust_id
HAVING
		SUM(CASE WHEN Prod_id = 'Prod_11' THEN 1 ELSE 0 END) >= 1
AND		SUM(CASE WHEN Prod_id = 'Prod_14' THEN 1 ELSE 0 END) >= 1)

SELECT Cust_id, P11, P14, TOTAL_PROD,
CAST(ROUND(AVG(P11/TOTAL_PROD) OVER(),3) AS DECIMAL(16,2))RATIO_P11,
CAST(ROUND(AVG(P14/TOTAL_PROD) OVER(),3) AS DECIMAL(16,2))RATIO_P14
FROM T1


--Customer Segmentation

-- Result of Q-1:
-- M��terilerin ziyaret g�nl�klerini ayl�k olarak tutan bir g�r�n�m olu�turun. 
-- (Her log i�in �� alan tutulur: Cust_id, Year, Month)

CREATE VIEW cus_viz_monthly
AS
SELECT Cust_id,
YEAR(Order_Date)YEAR, MONTH(Order_Date)MONTH
FROM dbo.combined_table

SELECT *
FROM cus_viz_monthly
ORDER BY Cust_id


-- Result of Q-2:
-- Kullan�c�lar�n ayl�k ziyaretlerinin say�s�n� tutan bir g�r�n�m olu�turun. 
-- (�� ba�lang�c�ndan itibaren t�m aylar i�in ayr� ayr�)

CREATE VIEW NUM_OF_LOG
AS
SELECT Cust_id, YEAR, MONTH, COUNT(*)NUM_OF_LOG
FROM cus_viz_monthly
GROUP BY Cust_id,YEAR, MONTH

SELECT *
FROM NUM_OF_LOG
ORDER BY 1

-- Result of Q-3:
-- M��terilerin her ziyareti i�in, ziyaretin bir sonraki ay�n� ayr� bir s�tun olarak olu�turun.


CREATE VIEW NEXT_VISIT AS
SELECT *,
        LEAD(CURRENT_MONTH, 1) OVER (PARTITION BY Cust_id ORDER BY CURRENT_MONTH) NEXT_VISIT_MONTH
FROM
(SELECT  *,
        DENSE_RANK () OVER (ORDER BY [YEAR] , [MONTH]) CURRENT_MONTH
FROM    NUM_OF_LOG) A



-- Result of Q-4:
-- Her m��terinin birbirini takip eden iki ziyareti aras�ndaki ayl�k zaman aral���n� hesaplay�n.

WITH T1 AS(
SELECT DISTINCT Cust_id,
AVG(NEXT_VISIT_MONTH - CURRENT_MONTH) OVER(PARTITION BY Cust_id)AVG_TIME_GAP
FROM NEXT_VISIT)

SELECT Cust_id, AVG_TIME_GAP,
CASE WHEN AVG_TIME_GAP IS NULL THEN 'Churn'
     WHEN AVG_TIME_GAP > 0 THEN 'irregular' END AS CUST_LABELS
FROM T1

-- Result of Q-5:
-- Ortalama zaman bo�luklar�n� kullanarak m��terileri kategorilere ay�r�n. Size en uygun etiketleme modelini se�in.

CREATE VIEW TIME_GAP AS
SELECT Cust_id, YEAR, MONTH, NUM_OF_LOG, CURRENT_MONTH, NEXT_VISIT_MONTH,
NEXT_VISIT_MONTH - CURRENT_MONTH TIME_GAPS
FROM NEXT_VISIT


--MONTH-W�SE RETENT�ON RATE


--Find month-by-month customer retention rate  since the start of the business.

-- Result of Q-1:
--1. Find the number of customers retained month-wise. (You can use time gaps)
--Use Time Gaps

-- Ay baz�nda elde tutulan m��teri say�s�n� bulun. (Zaman bo�luklar�n� kullanabilirsiniz)

CREATE VIEW RETENTION_MONTH AS
SELECT *,
COUNT(Cust_id) OVER (PARTITION BY CURRENT_MONTH)RETENTION_MONTH_WISE
FROM TIME_GAP
WHERE TIME_GAPS = 1

SELECT *
FROM RETENTION_MONTH
ORDER BY 1


-- Result of Q-2:
-- Ay baz�nda elde tutma oran�n� hesaplay�n.
-- o Ay Baz�nda Elde Tutma Oran� = 1.0 * �nceki Aydaki Toplam M��teri Say�s� / Sonraki Ayda Elde Tutulan M��teri Say�s�

CREATE VIEW Next_Month AS

SELECT YEAR, MONTH, COUNT(Cust_id) Cus_month,
LAG(COUNT(Cust_id),1) OVER(ORDER BY YEAR) Next_Month_Cus
FROM TIME_GAP
GROUP BY YEAR, MONTH


SELECT A.YEAR, A.MONTH,
LAG(CAST(ROUND(AVG(1.0*B.RETENTION_MONTH_WISE/A.Cus_month),2) AS DECIMAL(16,2)),1) OVER (ORDER BY A.MONTH)RETENTION_RATE 
FROM Next_Month A, RETENTION_MONTH B
WHERE A.YEAR = B.YEAR
GROUP BY A.YEAR, A.MONTH
ORDER BY YEAR, MONTH




