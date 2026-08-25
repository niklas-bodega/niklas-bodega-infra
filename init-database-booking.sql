CREATE DATABASE IF NOT EXISTS `bodega_booking_db`;

GRANT ALL PRIVILEGES ON `bodega_booking_db`.* TO 'bodega_user'@'%';

FLUSH PRIVILEGES;