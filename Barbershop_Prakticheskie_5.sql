USE Barbershop;
GO

-- ------------- Практическая 5, модуль 1 --------------

-- 1. Вернуть ФИО всех барберов
CREATE PROCEDURE GetAllBarbers
AS
BEGIN
    SELECT FullName
    FROM Barbers;
END;
GO

EXEC GetAllBarbers;
GO

-- 2. Вернуть информацию обо всех синьор-барберах
CREATE PROCEDURE GetSeniorBarbers
AS
BEGIN
    SELECT *
    FROM Barbers
    WHERE Position = N'Синьор-барбер';
END;
GO

EXEC GetSeniorBarbers;
GO

-- 3. Вернуть барберов, которые предоставляют услугу «Традиционное бритьё бороды»
CREATE PROCEDURE ShaveBarbers
AS
BEGIN
    SELECT B.FullName
    FROM Barbers B
    JOIN BarberServices BS ON B.BarberId = BS.BarberId
    JOIN Services S ON BS.ServiceId = S.ServiceId
    WHERE S.ServiceName = N'Традиционное бритьё бороды';
END;
GO

EXEC ShaveBarbers;
GO

-- 4. Вернуть барберов, которые предоставляют указанную услугу
CREATE PROCEDURE BarbersService
    @ServiceName NVARCHAR(100)
AS
BEGIN
    SELECT B.FullName
    FROM Barbers B
    JOIN BarberServices BS ON B.BarberId = BS.BarberId
    JOIN Services S ON BS.ServiceId = S.ServiceId
    WHERE S.ServiceName = @ServiceName;
END;
GO

EXEC BarbersService N'Традиционное бритьё бороды';
GO

-- 5. Вернуть барберов, которые работают больше указанного количества лет
CREATE PROCEDURE BarbersYears
    @Years INT
AS
BEGIN
    SELECT FullName, HireDate
    FROM Barbers
    WHERE DATEDIFF(YEAR, HireDate, GETDATE()) > @Years;
END;
GO

EXEC BarbersYears 2;
GO

-- 6. Вернуть количество синьор-барберов и джуниор-барберов
CREATE PROCEDURE CountBarbers
AS
BEGIN
    SELECT
        SUM(CASE WHEN Position = N'Синьор-барбер' THEN 1 ELSE 0 END) AS SeniorCount,
        SUM(CASE WHEN Position = N'Джуниор-барбер' THEN 1 ELSE 0 END) AS JuniorCount
    FROM Barbers;
END;
GO

EXEC CountBarbers;
GO

-- 7. Вернуть постоянных клиентов
CREATE PROCEDURE RegularClients
    @Visits INT
AS
BEGIN
    SELECT C.FullName, COUNT(V.VisitId) AS VisitCount
    FROM Clients C
    JOIN VisitArchive V ON C.ClientId = V.ClientId
    GROUP BY C.FullName
    HAVING COUNT(V.VisitId) >= @Visits;
END;
GO

EXEC RegularClients 3;
GO

-- 8. Запретить удаление чиф-барбера, если не добавлен второй чиф-барбер
CREATE TRIGGER DeleteChief
ON Barbers
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS
    (
        SELECT *
        FROM deleted
        WHERE Position = N'Чиф-барбер'
    )
    AND
    (
        SELECT COUNT(*)
        FROM Barbers
        WHERE Position = N'Чиф-барбер'
    ) <= 1
    BEGIN
        RAISERROR(N'Нельзя удалить единственного чиф-барбера', 16, 1);
        RETURN;
    END;

    DELETE FROM Barbers
    WHERE BarberId IN (SELECT BarberId FROM deleted);
END;
GO

-- 9. Запретить добавление барберов младше 21 года
CREATE TRIGGER BarberAge
ON Barbers
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS
    (
        SELECT *
        FROM inserted
        WHERE DATEDIFF(YEAR, BirthDate, GETDATE()) < 21
    )
    BEGIN
        RAISERROR(N'Нельзя добавить барбера младше 21 года', 16, 1);
        RETURN;
    END;

    INSERT INTO Barbers
        (FullName, Gender, Phone, Email, BirthDate, HireDate, Position)
    SELECT
        FullName, Gender, Phone, Email, BirthDate, HireDate, Position
    FROM inserted;
END;
GO

-- -------------- Практическая 5, модуль 2 -------------

-- 1. Вернуть информацию о барбере, который работает дольше всех
CREATE PROCEDURE OldBarber
AS
BEGIN
    SELECT TOP 1 *
    FROM Barbers
    ORDER BY HireDate ASC;
END;
GO

EXEC OldBarber;
GO

-- 2. Барбер, который обслужил максимальное количество клиентов за заданный период
CREATE PROCEDURE TopBarber
    @DateFrom DATE,
    @DateTo DATE
AS
BEGIN
    SELECT TOP 1
        B.FullName,
        COUNT(V.ClientId) AS ClientCount
    FROM Barbers B
    JOIN VisitArchive V ON B.BarberId = V.BarberId
    WHERE V.VisitDate BETWEEN @DateFrom AND @DateTo
    GROUP BY B.FullName
    ORDER BY ClientCount DESC;
END;
GO

EXEC TopBarber '20260901', '20260930';
GO

-- 3. Вернуть информацию о клиенте, который посещал барбершоп чаще всех
CREATE PROCEDURE TopClient
AS
BEGIN
    SELECT TOP 1
        C.FullName,
        COUNT(V.VisitId) AS VisitCount
    FROM Clients C
    JOIN VisitArchive V ON C.ClientId = V.ClientId
    GROUP BY C.FullName
    ORDER BY VisitCount DESC;
END;
GO

EXEC TopClient;
GO

-- 4. Клиент, который потратил больше всего денег
CREATE PROCEDURE RichClient
AS
BEGIN
    SELECT TOP 1
        C.FullName,
        SUM(V.TotalPrice) AS TotalSpent
    FROM Clients C
    JOIN VisitArchive V ON C.ClientId = V.ClientId
    GROUP BY C.FullName
    ORDER BY TotalSpent DESC;
END;
GO

EXEC RichClient;
GO

-- 5. Вернуть информацию о самой длительной услуге
CREATE PROCEDURE LongService
AS
BEGIN
    SELECT TOP 1 *
    FROM Services
    ORDER BY DurationMinutes DESC;
END;
GO

EXEC LongService;
GO

-- ----------------------- Задание 2 -------------------------------

-- 1. Самый популярный барбер
CREATE PROCEDURE PopularBarber
AS
BEGIN
    SELECT TOP 1
        B.FullName,
        COUNT(V.ClientId) AS ClientCount
    FROM Barbers B
    JOIN VisitArchive V ON B.BarberId = V.BarberId
    GROUP BY B.FullName
    ORDER BY ClientCount DESC;
END;
GO

EXEC PopularBarber;
GO

-- 2. ТОП-3 барберов за месяц
CREATE PROCEDURE Top3Barbers
    @DateFrom DATE,
    @DateTo DATE
AS
BEGIN
    SELECT TOP 3
        B.FullName,
        SUM(V.TotalPrice) AS TotalMoney
    FROM Barbers B
    JOIN VisitArchive V ON B.BarberId = V.BarberId
    WHERE V.VisitDate BETWEEN @DateFrom AND @DateTo
    GROUP BY B.FullName
    ORDER BY TotalMoney DESC;
END;
GO

EXEC Top3Barbers '20260901', '20260930';
GO

-- 3. ТОП-3 барберов за всё время по средней оценке
CREATE PROCEDURE Top3Rating
AS
BEGIN
    SELECT TOP 3
        B.FullName,
        AVG(CAST(V.Rating AS FLOAT)) AS AvgRating
    FROM Barbers B
    JOIN VisitArchive V ON B.BarberId = V.BarberId
    GROUP BY B.FullName
    HAVING COUNT(V.VisitId) >= 30
    ORDER BY AvgRating DESC;
END;
GO

EXEC Top3Rating;
GO

-- 4. Показать расписание барбера на определённый день
CREATE PROCEDURE DaySchedule
    @BarberId INT,
    @WorkDate DATE
AS
BEGIN
    SELECT *
    FROM BarberSchedule
    WHERE BarberId = @BarberId
      AND WorkDate = @WorkDate;
END;
GO

EXEC DaySchedule 1, '20260925';
GO

-- 5. Показать свободные временные окна барбера на неделю
CREATE PROCEDURE FreeTime
    @BarberId INT
AS
BEGIN
    SELECT
        S.WorkDate,
        S.StartTime,
        S.EndTime
    FROM BarberSchedule S
    WHERE S.BarberId = @BarberId
      AND S.WorkDate BETWEEN CAST(GETDATE() AS DATE)
                         AND DATEADD(DAY, 7, CAST(GETDATE() AS DATE))
      AND NOT EXISTS
      (
          SELECT *
          FROM Appointments A
          WHERE A.BarberId = S.BarberId
            AND CAST(A.AppointmentDate AS DATE) = S.WorkDate
      );
END;
GO

EXEC FreeTime 1;
GO

-- 6. Перенести завершённые услуги в архив
CREATE PROCEDURE ToArchive
AS
BEGIN
    INSERT INTO VisitArchive
        (ClientId, BarberId, VisitDate, TotalPrice, Rating, Feedback)
    SELECT
        A.ClientId,
        A.BarberId,
        A.AppointmentDate,
        SUM(S.Price),
        NULL,
        NULL
    FROM Appointments A
    JOIN AppointmentServices APS
        ON A.AppointmentId = APS.AppointmentId
    JOIN Services S
        ON APS.ServiceId = S.ServiceId
    WHERE A.AppointmentDate < GETDATE()
    GROUP BY
        A.AppointmentId,
        A.ClientId,
        A.BarberId,
        A.AppointmentDate;
END;
GO

EXEC ToArchive;
GO

-- 7. Запретить запись на уже занятые дату и время
CREATE TRIGGER BusyTime
ON Appointments
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS
    (
        SELECT *
        FROM inserted I
        JOIN Appointments A
            ON I.BarberId = A.BarberId
           AND I.AppointmentDate = A.AppointmentDate
    )
    BEGIN
        RAISERROR(N'Это время у барбера уже занято', 16, 1);
        RETURN;
    END;

    INSERT INTO Appointments
        (ClientId, BarberId, AppointmentDate)
    SELECT
        ClientId, BarberId, AppointmentDate
    FROM inserted;
END;
GO

-- 8. Ограничение для джуниор-барберов: нельзя добавить больше 5 джуниор-барберов
CREATE TRIGGER JuniorLimit
ON Barbers
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS
    (
        SELECT *
        FROM inserted
        WHERE Position = N'Джуниор-барбер'
    )
    AND
    (
        SELECT COUNT(*)
        FROM Barbers
        WHERE Position = N'Джуниор-барбер'
    ) >= 5
    BEGIN
        RAISERROR(N'Нельзя добавить больше 5 джуниор-барберов', 16, 1);
        RETURN;
    END;

    INSERT INTO Barbers
        (FullName, Gender, Phone, Email, BirthDate, HireDate, Position)
    SELECT
        FullName, Gender, Phone, Email, BirthDate, HireDate, Position
    FROM inserted;
END;
GO

-- 9. Клиенты без отзывов и оценок
CREATE PROCEDURE NoReviews
AS
BEGIN
    SELECT C.*
    FROM Clients C
    WHERE NOT EXISTS
    (
        SELECT *
        FROM Reviews R
        WHERE R.ClientId = C.ClientId
    );
END;
GO

EXEC NoReviews;
GO

-- 10. Клиенты, которые не посещали барбершоп больше года
CREATE PROCEDURE OldClients
AS
BEGIN
    SELECT C.*
    FROM Clients C
    WHERE NOT EXISTS
    (
        SELECT *
        FROM VisitArchive V
        WHERE V.ClientId = C.ClientId
          AND V.VisitDate > DATEADD(YEAR, -1, GETDATE())
    );
END;
GO

EXEC OldClients;
GO
