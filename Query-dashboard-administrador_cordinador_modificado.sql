-- Administrador (los dashboard de los coordinadores tambien lo pueden ver el administrador ya que este tiene potestad sobre este)
-- ver coordinadores por zona
SELECT z.nombre AS zona, COUNT(u.usuario_id) AS total_encuestadores, u.estado,
    (COUNT(u.usuario_id) / (SELECT COUNT(*) FROM usuarios where u.estado = 2 and usuarios.estado = 'activo') * 100) AS porcentaje_usuarios
FROM usuarios u 
JOIN zonas z ON u.zona_id = z.zona_id 
WHERE u.rol_id = 2 AND u.estado = 'activo' -- desactivo, baneado
GROUP BY z.zona_id;

-- resumen total de usuarios
SELECT 
    -- Resumen de usuarios
    (SELECT COUNT(*) FROM usuarios WHERE rol_id = (SELECT rol_id FROM roles WHERE nombre = 'administrador')) AS total_administradores,
    (SELECT COUNT(*) FROM usuarios WHERE rol_id = (SELECT rol_id FROM roles WHERE nombre = 'coordinador')) AS total_coordinadores,
    (SELECT COUNT(*) FROM usuarios WHERE rol_id = (SELECT rol_id FROM roles WHERE nombre = 'encuestador')) AS total_encuestadores,
    
    -- Actividad reciente
    (SELECT COUNT(*) FROM respuestas WHERE fecha_envio >= CURDATE() - INTERVAL 7 DAY) AS respuestas_ultima_semana,
    
    -- Distribución geográfica
    (SELECT COUNT(DISTINCT dni_encuestado) FROM respuestas r JOIN usuarios u ON r.encuestador_id = u.usuario_id JOIN zonas z ON u.zona_id = z.zona_id WHERE z.nombre = 'Norte') AS encuestados_zona_norte,
    (SELECT COUNT(DISTINCT dni_encuestado) FROM respuestas r JOIN usuarios u ON r.encuestador_id = u.usuario_id JOIN zonas z ON u.zona_id = z.zona_id WHERE z.nombre = 'Sur') AS encuestados_zona_sur,
    
    -- Estado de usuarios
    (SELECT COUNT(*) FROM usuarios WHERE estado = 'activo') AS usuarios_activos,
    (SELECT COUNT(*) FROM usuarios WHERE estado = 'inactivo') AS usuarios_inactivos,
    (SELECT COUNT(*) FROM usuarios WHERE estado = 'baneado') AS usuarios_baneados,
    
    -- Última actualización
    NOW() AS ultima_actualizacion;


-- coordinador

   --- ENCUESTADORES --

-- Ver encuestadores (estados) por zonas total 
SELECT z.nombre AS zona, COUNT(u.usuario_id) AS total_encuestadores, u.estado,
    (COUNT(u.usuario_id) / (SELECT COUNT(*) FROM usuarios where usuarios.rol_id = 1 and usuarios.estado = 'activo') * 100) AS porcentaje_usuarios 
FROM usuarios u 
JOIN zonas z ON u.zona_id = z.zona_id 
WHERE u.rol_id = 1 AND u.estado = 'activo' -- desactivo, baneado
GROUP BY z.zona_id;

-- Ver encuestadores (estados) por distritos total 
SELECT d.nombre AS distrito, COUNT(u.usuario_id) AS total_encuestadores, u.estado,
    (COUNT(u.usuario_id) / (SELECT COUNT(*) FROM usuarios where usuarios.rol_id = 1 and usuarios.estado = 'activo') * 100) AS porcentaje_usuarios 
FROM usuarios u 
JOIN distritos d ON u.distrito_id = d.distrito_id 
WHERE u.rol_id = 1 AND u.estado = 'activo' -- desactivo, baneado
GROUP BY d.distrito_id;

-- Respuestas hechas por encuestador total  (distrito) //
SELECT	
    u.codigo_unico_encuestador,
    concat(u.nombre," ",u.apellido_paterno," ",u.apellido_materno) AS encuestador,
    d.nombre as distrito, 
    COUNT(r.respuesta_id) AS total_respuestas,
    (COUNT(r.respuesta_id) / (SELECT COUNT(*) FROM respuestas) * 100) AS porcentaje_respuestas
FROM usuarios u
INNER JOIN respuestas r ON u.usuario_id = r.encuestador_id
INNER JOIN distritos d ON u.distrito_id = d.distrito_id
WHERE u.rol_id = '1'    -- Filtrar solo encuestadores
GROUP BY u.usuario_id;


-- Respuestas completas por zonas // OBS
SELECT 
    z.zona_id,
    z.nombre AS zona,
    COUNT(u.usuario_id) AS total_encuestadores,
    COUNT(r.respuesta_id) AS "respuestas-completadas",
    (COUNT(r.respuesta_id) / (SELECT COUNT(*) FROM respuestas) * 100) AS "porcentaje" -- del total
FROM 
    zonas z
LEFT JOIN distritos d ON z.zona_id = d.zona_id
LEFT JOIN usuarios u ON d.distrito_id = u.distrito_id
LEFT JOIN respuestas r ON u.usuario_id = r.encuestador_id AND r.estado = 'completo' 

GROUP BY 
    z.zona_id
ORDER BY 
    "respuestas-completadas" DESC;
-- 
-- Respuestas borrador por zonas // OBS

SELECT 
    z.zona_id,
    z.nombre AS zona,
    COUNT(u.usuario_id) AS total_encuestadores,
    COUNT(r.respuesta_id) AS "respuestas-borrador",
    (COUNT(r.respuesta_id) / (SELECT COUNT(*) FROM respuestas) * 100) AS "porcentaje" -- del total
FROM 
    zonas z
LEFT JOIN distritos d ON z.zona_id = d.zona_id
LEFT JOIN usuarios u ON d.distrito_id = u.distrito_id
LEFT JOIN respuestas r ON u.usuario_id = r.encuestador_id AND r.estado = 'borrador' 

GROUP BY 
    z.zona_id
ORDER BY 
    "respuestas-incompletas" DESC;
--

--   VER ENCUESTADO

-- Ver encuestados por 
  
SELECT 
    z.zona_id,
    z.nombre AS zona,
    COUNT(DISTINCT r.dni_encuestado) AS "total de encuestados",
    (COUNT(r.dni_encuestado) / (SELECT COUNT(*) FROM respuestas) * 100) AS "porcentaje de encuestados" 
FROM 
    respuestas r
JOIN usuarios u ON r.encuestador_id = u.usuario_id
JOIN distritos d ON u.distrito_id = d.distrito_id
JOIN zonas z ON d.zona_id = z.zona_id
GROUP BY 
    z.zona_id
ORDER BY 
    "total de encuestados" DESC;
-- Ver encuestados por distritos 
SELECT 
    d.nombre AS distrito,
    COUNT(DISTINCT r.dni_encuestado) AS "total de encuestados",
    (COUNT(r.dni_encuestado) / (SELECT COUNT(*) FROM respuestas) * 100) AS "porcentaje de encuestados" 
FROM 
    respuestas r
JOIN usuarios u ON r.encuestador_id = u.usuario_id
JOIN distritos d ON u.distrito_id = d.distrito_id
GROUP BY 
    d.distrito_id
ORDER BY 
    "total de encuestados" DESC;


-- REPORTE DEL ADMI

-- Descargar reporte fecha de inicio de un rango de fechas (semanal,mensual,anual)
SELECT 
    r.respuesta_id,
    u.codigo_unico_encuestador,
    concat(u.nombre," ",u.apellido_paterno," ",u.apellido_materno) AS "nombre y apellidos",
    d.nombre AS distrito,
    z.nombre AS zona,
    DATE(r.fecha_inicio) AS fecha_inicio
FROM 
    respuestas r
JOIN usuarios u ON r.encuestador_id = u.usuario_id
JOIN distritos d ON u.distrito_id = d.distrito_id
JOIN zonas z ON d.zona_id = z.zona_id
WHERE 
    r.estado = 'completo'
    AND DATE(r.fecha_inicio) BETWEEN '2025-04-01' AND '2025-04-30'
ORDER BY 
    r.fecha_inicio ASC;
--

-- Descargar reporte fecha de envio de un rango de fechas (semanal,mensual,anual)
SELECT 
    r.respuesta_id,
    u.codigo_unico_encuestador,
    concat(u.nombre," ",u.apellido_paterno," ",u.apellido_materno) AS "nombre y apellidos",
    d.nombre AS distrito,
    z.nombre AS zona,
    DATE(r.fecha_envio) AS fecha_envio
FROM 
    respuestas r
JOIN usuarios u ON r.encuestador_id = u.usuario_id
JOIN distritos d ON u.distrito_id = d.distrito_id
JOIN zonas z ON d.zona_id = z.zona_id
WHERE 
    r.estado = 'completo'
    AND DATE(r.fecha_envio) BETWEEN '2023-06-01' AND '2023-06-30'
ORDER BY 
    r.fecha_envio;
    
-- Descargar reporte de las acciones que hizo el administrador
SELECT concat(u.nombre," ",u.apellido_paterno) as "nombre y apellidos",l.accion, l.detalle, l.fecha_log
FROM logs_actividades l
JOIN usuarios u ON l.usuario_id = u.usuario_id
WHERE u.rol_id = 3
ORDER BY l.fecha_log DESC;