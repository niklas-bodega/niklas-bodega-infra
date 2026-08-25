CREATE DATABASE IF NOT EXISTS `bodega_user_db`;

GRANT ALL PRIVILEGES ON `bodega_user_db`.* TO 'bodega_user'@'%';

FLUSH PRIVILEGES;