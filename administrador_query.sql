
-- ver perfil administrador
SELECT 
    concat(u.nombre,' ',u.apellido_paterno,' ',u.apellido_materno) as "nombre completo",
    u.dni, u.correo, u.direccion, u.estado, u.fecha_registro, u.ultima_conexion,
    d.nombre AS nombre_distrito, z.nombre AS nombre_zona, r.nombre AS rol
FROM 
    usuarios u
LEFT JOIN distritos d ON u.distrito_id = d.distrito_id
LEFT JOIN zonas z ON u.zona_id = z.zona_id
INNER JOIN roles r ON u.rol_id = r.rol_id
WHERE 
    u.usuario_id = 2
    AND r.nombre = 'administrador' -- cambiamos de acuerdo al rol (admi,coordi,encuestador);
--

-- Ver los datos del coordiandor cuando se le ha registrado
SELECT u.nombre, u.apellido_paterno, u.apellido_materno, u.dni, d.nombre AS distrito, z.nombre AS zona  ,u.correo
FROM usuarios u
JOIN zonas z ON u.zona_id = z.zona_id
INNER JOIN distritos d ON u.distrito_id = d.distrito_id
WHERE u.rol_id = 2 AND z.zona_id = 1;	


-- ver coordinadores desde el administrador // cuadro
SELECT 
    u.dni AS codigo_coordinador, CONCAT(u.nombre, ' ', u.apellido_paterno, ' ', u.apellido_materno) AS "nombre completo",
    z.nombre AS "zona asignada", d.nombre AS "distrito", r.nombre AS rol, u.estado
FROM 
    usuarios u
LEFT JOIN distritos d ON u.distrito_id = d.distrito_id
LEFT JOIN zonas z ON u.zona_id = z.zona_id
INNER JOIN roles r ON u.rol_id = r.rol_id
WHERE 
    r.nombre = 'coordinador'
ORDER BY 
    CASE 
        WHEN u.estado = 'activo' THEN 1 
        WHEN u.estado = 'inactivo' THEN 2 
        ELSE 3 
    END, 
    u.estado;
--
		
-- ver encuestadores a cargo de coordinadores desde el administrador // cuadro
SELECT 
    u.usuario_id, u.codigo_unico_encuestador as "codigo-encuestador",
    u.nombre, concat(u.apellido_paterno," ",u.apellido_materno) as apellidos,
    u.correo, d.nombre AS distrito, ea.estado AS estado_encuesta, u.estado
FROM 
    usuarios u
INNER JOIN zonas z ON u.zona_id = z.zona_id
left JOIN distritos d ON u.distrito_id = d.distrito_id
left JOIN roles r ON u.rol_id = r.rol_id
left JOIN encuestas_asignadas ea ON u.usuario_id = ea.coordinador_id
WHERE 
    u.zona_id = (SELECT zona_id FROM usuarios WHERE usuario_id = 7)  -- Zona del coordinador
    AND r.nombre = 'encuestador' 
ORDER BY 
    u.nombre;

-- obtener las credenciales del administrador
SELECT u.usuario_id, u.nombre, concat(u.apellido_paterno," ",u.apellido_materno) as apellidos, r.nombre as cargo , u.contrasena_hash
FROM usuarios u
INNER JOIN roles r ON r.rol_id = u.rol_id
WHERE r.nombre = 'administrador'  -- Aquí es el correo ingresado por el usuario

-- ver actividades recientes
SELECT 
u.usuario_id, u.nombre, CONCAT(u.apellido_paterno, ' ', u.apellido_materno) AS apellidos,
 r.nombre as cargo, l.accion, l.detalle, l.fecha_log as dia_y_fecha, u.ultima_conexion
FROM logs_actividades l
JOIN usuarios u ON l.usuario_id = u.usuario_id
JOIN roles r ON u.rol_id = r.rol_id
ORDER BY l.fecha_log DESC

-- ver usuarios que no han validado su correo
SELECT u.usuario_id , u.nombre, concat(u.apellido_paterno," ",u.apellido_materno) as apellidos , u.correo_verificado
FROM usuarios u
INNER JOIN roles r ON u.rol_id = r.rol_id
WHERE r.nombre = 'coordinador'
ORDER BY correo_verificado ASC; -- aquí podemos saber cuantos faltan verificar correo


-- ver estado de respuestas de encuestas por distrito de una zona

SELECT 
    d.distrito_id,
    d.nombre AS distrito,
	COUNT(CASE WHEN r.estado = 'completo' THEN 1 END) AS respuestas_completas,
    COUNT(CASE WHEN r.estado != 'completo' THEN 1 END) AS respuestas_incompletas
FROM 
    distritos d
LEFT JOIN usuarios u ON d.distrito_id = u.distrito_id
LEFT JOIN respuestas r ON u.usuario_id = r.encuestador_id 
WHERE 
    d.zona_id = (SELECT zona_id FROM usuarios WHERE usuario_id = 3)  -- Zona del coordinador
GROUP BY 
    d.distrito_id
ORDER BY 
    respuestas_completas DESC;


-- ver estado de respuestas de encuestas por zona

SELECT 
    z.zona_id,
    z.nombre AS zona,
    COUNT(CASE WHEN r.estado = 'completo' THEN 1 END) AS respuestas_completas,
    COUNT(CASE WHEN r.estado != 'completo' THEN 1 END) AS respuestas_incompletas
FROM 
    zonas z
LEFT JOIN distritos d ON z.zona_id = d.zona_id
LEFT JOIN usuarios u ON d.distrito_id = u.distrito_id
LEFT JOIN respuestas r ON u.usuario_id = r.encuestador_id
GROUP BY 
    z.zona_id
ORDER BY 
    respuestas_completas DESC;

-- ver estado de respuestas de encuestas por encuestador de un distrito de la zona especifica

SELECT 
    u.usuario_id,
    u.codigo_unico_encuestador,
    CONCAT(u.nombre, ' ', u.apellido_paterno) AS encuestador,
    d.nombre AS distrito,
	COUNT(CASE WHEN r.estado = 'completo' THEN 1 END) AS respuestas_completas,
    COUNT(CASE WHEN r.estado != 'completo' THEN 1 END) AS respuestas_incompletas
FROM 
    usuarios u
INNER JOIN distritos d ON u.distrito_id = d.distrito_id
LEFT JOIN respuestas r ON u.usuario_id = r.encuestador_id 
WHERE 
    u.zona_id = (SELECT zona_id FROM usuarios WHERE usuario_id = 3)  -- Zona del coordinador
    AND u.rol_id = (SELECT rol_id FROM roles WHERE nombre = 'encuestador')
GROUP BY 
    u.usuario_id  
ORDER BY 
    respuestas_completas DESC;