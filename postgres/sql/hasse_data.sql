/*
-- Reset?
DELETE FROM sys_meta.groups;
DELETE FROM sys_meta.users;
*/

-- Minimal Vertex:
INSERT INTO sys_meta.groups(RoleName, Minimal, Comment)
VALUES ('nobody', TRUE, 'Minimal Hasse Vertex');

-- Maximal Vertex and highest edges:
INSERT INTO sys_meta.groups(RoleName, Maximal, RoleGroups, Comment)
VALUES ('superuser', TRUE, '{chief,administrator}', 'Maximal Hasse Vertex');

-- Hasse Vertices and edges:
INSERT INTO sys_meta.groups(RoleName, RoleGroups) VALUES
('administrator',  '{auditor,www}'),
('chief',          '{manager,supervisor}'),
('manager',        '{operator,validator}'),
('supervisor',     '{administrative}'),
('operator',       '{scientific}'),
('validator',      '{scientific,student,technician}'),
('auditor',        '{revisor}'),
('student',        '{anybody}'),
('scientific',     '{anybody}'),
('technician',     '{anybody}'),
('administrative', '{anybody}'),
('revisor',        '{anybody}'),
('www',            '{anybody}'),
('anybody',        '{nobody}')
;

-- Owner:
INSERT INTO sys_meta.users(RoleName, RoleGroups, Ownership) VALUES
('samantha',    '{superuser}', TRUE);

-- Extended Graph:
INSERT INTO sys_meta.users(RoleName, RoleGroups) VALUES
('catharina',   '{chief}'),
('anatole',     '{administrator}'),
('deamon',      '{manager}'),
('manuel',      '{manager}'),
('megan',       '{supervisor}'),
('marta',       '{manager,administrative,revisor}'),
('olivia',      '{operator}'),
('veronika',    '{validator}'),
('sabine',      '{scientific}'),
('seraphin',    '{scientific}'),
('sarah',       '{student}'),
('theo',        '{technician}'),
('aaron',       '{administrative}'),
('webservice',  '{www}'),
('sammy',       '{anybody}'),
('nancy',       '{nobody}');




