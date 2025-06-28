# sql-hex-grid
Хранимая SQL функция для построения сетки из шестигранников в указанном охвате координат.

Функция `generate_hex_grid_meters` использует функции расширения PostGIS.

Пример использования:
```sql
SELECT * FROM generate_hex_grid_meters(
    x_min := 50.0,
    y_min := 56.0,
    x_max := 51.0,
    y_max := 57.0,
    cell_size := 5000  -- 5 км
);
```
