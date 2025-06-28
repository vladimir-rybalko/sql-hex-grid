CREATE OR REPLACE FUNCTION generate_hex_grid_meters(
    x_min DOUBLE PRECISION, -- долгота (в градусах)
    y_min DOUBLE PRECISION, -- широта (в градусах)
    x_max DOUBLE PRECISION,
    y_max DOUBLE PRECISION,
    cell_size DOUBLE PRECISION -- в метрах
)

RETURNS TABLE (
    cell_id TEXT,
    geometry GEOMETRY(POLYGON, 4326),
    centroid GEOMETRY(POINT, 4326)
) AS $$
DECLARE
    dx DOUBLE PRECISION := 3 * cell_size;
    dy DOUBLE PRECISION := sqrt(3) * cell_size;
    row_offset DOUBLE PRECISION;
    x DOUBLE PRECISION;
    y DOUBLE PRECISION;
    row INT := 0;
    col INT;
    cx DOUBLE PRECISION;
    cy DOUBLE PRECISION;
    hex geometry;
    env3857 geometry;
BEGIN
    -- Преобразуем envelope в метрическую систему координат
    env3857 := ST_Transform(
        ST_MakeEnvelope(x_min, y_min, x_max, y_max, 4326),
        3857
    );

    y := ST_YMin(env3857);

    WHILE y < ST_YMax(env3857) + dy LOOP
        col := 0;
        row_offset := (row % 2) * (dx / 2);
        x := ST_XMin(env3857) - dx;

        WHILE x < ST_XMax(env3857) + dx LOOP
            cx := x + dx + row_offset;
            cy := y;

            -- Построение гексагона в метрах
            hex := st_setSRID(ST_MakePolygon(ST_MakeLine(ARRAY[
                ST_MakePoint(cx + cell_size * cos(radians(0)),   cy + cell_size * sin(radians(0))),
                ST_MakePoint(cx + cell_size * cos(radians(60)),  cy + cell_size * sin(radians(60))),
                ST_MakePoint(cx + cell_size * cos(radians(120)), cy + cell_size * sin(radians(120))),
                ST_MakePoint(cx + cell_size * cos(radians(180)), cy + cell_size * sin(radians(180))),
                ST_MakePoint(cx + cell_size * cos(radians(240)), cy + cell_size * sin(radians(240))),
                ST_MakePoint(cx + cell_size * cos(radians(300)), cy + cell_size * sin(radians(300))),
                ST_MakePoint(cx + cell_size * cos(radians(0)),   cy + cell_size * sin(radians(0)))
            ])), 3857);

            -- Фильтрация по исходному bbox (в метрах)
            IF ST_Intersects(hex, env3857) THEN
                -- Преобразуем обратно в WGS 84 (градусы)
	            RETURN QUERY
	            SELECT 
	                md5(concat((x - x_min) / cell_size, '-', (y - y_min) / cell_size)) AS cell_id,
	
	                -- Строим шестиугольник в проекции 3857 и переводим обратно в WGS84
	                ST_Transform( hex, 4326 )::GEOMETRY(POLYGON, 4326) AS geometry,
	
	                -- Центр ячейки
	                ST_Transform(ST_Centroid(hex), 4326)::GEOMETRY(POINT, 4326) AS centroid;
            END IF;

            col := col + 1;
            x := x + dx;
        END LOOP;

        row := row + 1;
        y := y + dy * 0.5;
    END LOOP;

    RETURN;
END;
$$ LANGUAGE plpgsql;
