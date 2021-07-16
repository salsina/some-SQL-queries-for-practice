create database company;

use company;

# 1
select p.ProductName
from products p
where p.UnitPrice > 15 and p.UnitPrice < 20 ;

# 2
select p.ProductName, p.UnitPrice
from products p
where p.UnitPrice = (select min(p2.UnitPrice) 
						from products p2);

# 3
select p.ProductName, p.UnitsInStock
from products p
where p.UnitsInStock = (select max(p2.UnitsInStock)
						from products p2) limit 1;

# 4
select count(*)
from employees e
where e.Salary > 2000
union
select count(*)
from employees e
where e.Salary < 1800;

# 5
select cat.CategoryName, avg(p.UnitPrice) as average_price
from products p, categories cat
where cat.CategoryID = p.CategoryID
group by p.CategoryID
having avg(p.UnitPrice)  > 25;

# 6
select distinct C.ContactName
from customers C, orders O
where C.ContactName like 'M%' and 
	O.CustomerID = C.CustomerID and 
    O.ShipVia = (select S.ShipperID 
				from shippers S 
                where S.CompanyName like "Federal Shipping");

# 7
select emp.FirstName, emp.LastName
from employees emp
where emp.ReportsTo is null and
	(select distinct count(*)
			from employees emp2
			where emp2.ReportsTo = emp.EmployeeID) > 0;

# 8
select O.OrderID, sum(O.UnitPrice * O.Quantity) as total
from `order details` O
group by O.OrderID;

# 9
select count(distinct C.CustomerID)
from Customers C, Orders O, (select O_details.OrderID, sum(O_details.Quantity * O_details.UnitPrice ) as total
								from `order details` O_details 
                                group by O_details.OrderID) as grouped_orders
where  O.OrderID = grouped_orders.OrderID and C.CustomerID = O.CustomerID and grouped_orders.total > 5000 ;

# 10
select ter.TerritoryDescription
from territories ter
where ter.TerritoryID not in (select emp_ter.TerritoryID 
								from employeeterritories emp_ter);

# 11
select C.ContactName
from customers C
where (select count(distinct O.EmployeeID)
		from orders O
		where O.CustomerID = C.CustomerID) = 2;
        
# 12
create view custName_total as
	select C1.ContactName, grouped_customers.sum_total
	from Customers C1,  (select C2.CustomerID, sum(grouped_orders.total_order) as sum_total
							from Customers C2, Orders O, (select O_details.OrderID, sum(O_details.Quantity * O_details.UnitPrice ) as total_order
								from `order details` O_details 
								group by O_details.OrderID) as grouped_orders
							where C2.CustomerID = O.CustomerID and O.orderID = grouped_orders.orderID
							group by C2.CustomerID) as grouped_customers
	where  C1.CustomerID = grouped_customers.CustomerID ;
select * from custName_total;

# 13
create view employeeName_reporters as
	select emp.FirstName, emp.LastName, (select count(*)
							from employees emp2
							where emp2.ReportsTo = emp.EmployeeID) as reportersNumber
	from employees emp
	group by emp.EmployeeID
	having reportersNumber > 0;
select * from employeeName_reporters;

# 14 
drop view supplierName_zeroSuppliedProducts;
create view supplierName_zeroSuppliedProducts as
	select S.CompanyName, (select count(*) 
				from products P
				where P.UnitsInStock = 0 and P.SupplierID = S.SupplierID) as zeroSuppliedProducts
	from suppliers S;
select * from supplierName_zeroSuppliedProducts;

#15
DELIMITER // 
create trigger check_price 
before insert on `order details`
for each row begin
	if ( (select P.UnitPrice 
			from products P 
			where P.ProductID = new.ProductID) != new.UnitPrice ) then
            signal sqlstate '45000' set message_text = "Invalid Price: Price is inconsistent";
	end if;
end;//
DELIMITER ;

-- select * from `order details`;
-- delete from `order details` o where o.ProductID = 1 and o.OrderID=10248 and o.Quantity = 60;
-- insert into `order details`(OrderID,ProductID,UnitPrice,Quantity) values(10248,11,20.0000,60);
-- select p.UnitPrice from products p where p.ProductID = 11;

# 16
drop trigger check_quantity;
DELIMITER // 
create trigger check_quantity
before insert on `order details`
for each row begin
	if ( (select P.UnitsInStock 
			from products P 
			where P.ProductID = new.ProductID) < new.Quantity ) then
				signal sqlstate '45000' set message_text = "Invalid Quantity: Quantity is higher than UnitInStock";
    else 
		update products P2 set P2.UnitsInStock = P2.UnitsInStock - new.Quantity where P2.ProductID = new.ProductID;
    end if;
end;//
DELIMITER ;   

# 17
DELIMITER // 
create trigger check_Dr
before update on employees
for each row begin
	if (old.TitleOfCourtesy != new.TitleOfCourtesy) then
		if (old.TitleOfCourtesy = "Dr.") then
			set new.salary = new.salary / 2;
		end if;
		if (new.TitleOfCourtesy = "Dr.") then
			set new.salary = new.salary * 2;
		end if;
	end if;
end;//
DELIMITER ;   
