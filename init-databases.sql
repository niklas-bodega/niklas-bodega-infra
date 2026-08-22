CREATE DATABASE IF NOT EXISTS `bodega_user_db`;
CREATE DATABASE IF NOT EXISTS `bodega_booking_db`;
CREATE DATABASE IF NOT EXISTS `bodega_review_db`;

GRANT ALL PRIVILEGES ON `bodega_user_db`.* TO 'bodega_user'@'%';
GRANT ALL PRIVILEGES ON `bodega_booking_db`.* TO 'bodega_user'@'%';
GRANT ALL PRIVILEGES ON `bodega_review_db`.* TO 'bodega_user'@'%';

FLUSH PRIVILEGES;