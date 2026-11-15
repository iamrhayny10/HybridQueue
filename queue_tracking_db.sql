-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Nov 14, 2026 at 08:34 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `queue_tracking_db`
--

-- --------------------------------------------------------

--
-- Table structure for table `activity_logs`
--

CREATE TABLE `activity_logs` (
  `log_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `action_type` varchar(100) NOT NULL,
  `action_detail` text NOT NULL,
  `logged_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `activity_logs`
--

INSERT INTO `activity_logs` (`log_id`, `user_id`, `action_type`, `action_detail`, `logged_at`) VALUES
(1, 2, 'login', 'User logged in', '2026-10-19 12:26:22'),
(2, 1, 'login', 'User logged in', '2026-10-19 12:34:31'),
(3, 1, 'base_time_update', 'Base time for Registrar set to 5 min.', '2026-10-19 12:35:07'),
(4, 1, 'base_time_update', 'Base time for Cashier set to 5 min.', '2026-10-19 12:35:08'),
(5, 1, 'base_time_update', 'Base time for OSA set to 3 min.', '2026-10-19 12:35:09'),
(6, 8, 'register', 'Student registered ID:2026-10-00022 Name:Rhayn Mercader', '2026-10-19 12:36:34'),
(7, 8, 'login', 'User logged in', '2026-10-19 12:37:03'),
(8, 8, 'ticket_issued', 'Ticket R-001 [Registrar] ERT:5min', '2026-10-19 12:37:11'),
(9, 2, 'login', 'User logged in', '2026-10-19 12:37:44'),
(10, 2, 'ticket_called', 'Ticket R-001 [Registrar] called to window 1', '2026-10-19 12:37:49'),
(11, 2, 'ticket_served', 'Ticket R-001 served. Wait:0.63min', '2026-10-19 12:37:56'),
(12, 8, 'ticket_issued', 'Ticket R-002 [Registrar] ERT:5min', '2026-10-19 12:38:14'),
(13, 2, 'ticket_called', 'Ticket R-002 [Registrar] called to window 1', '2026-10-19 12:38:33'),
(14, 2, 'ticket_served', 'Ticket R-002 served. Wait:0.32min', '2026-10-19 12:38:35'),
(15, 8, 'ticket_issued', 'Ticket R-003 [Registrar] ERT:5min', '2026-10-19 12:38:52'),
(16, 2, 'ticket_called', 'Ticket R-003 [Registrar] called to window 1', '2026-10-19 12:39:04'),
(17, 2, 'ticket_served', 'Ticket R-003 served. Wait:0.2min', '2026-10-19 12:39:06'),
(18, 8, 'ticket_issued', 'Ticket R-004 [Registrar] ERT:5min', '2026-10-19 12:39:25'),
(19, 2, 'ticket_called', 'Ticket R-004 [Registrar] called to window 1', '2026-10-19 12:39:45'),
(20, 2, 'ticket_served', 'Ticket R-004 served. Wait:0.33min', '2026-10-19 12:39:47'),
(21, 8, 'ticket_issued', 'Ticket R-005 [Registrar] ERT:5min', '2026-10-19 12:39:57'),
(22, 2, 'ticket_called', 'Ticket R-005 [Registrar] called to window 1', '2026-10-19 12:40:08'),
(23, 2, 'ticket_served', 'Ticket R-005 served. Wait:0.18min', '2026-10-19 12:40:11'),
(24, 8, 'ticket_issued', 'Ticket R-006 [Registrar] ERT:5min', '2026-10-19 12:40:22'),
(25, 2, 'ticket_called', 'Ticket R-006 [Registrar] called to window 1', '2026-10-19 12:40:29'),
(26, 2, 'ticket_served', 'Ticket R-006 served. Wait:0.12min', '2026-10-19 12:40:31'),
(27, 8, 'ticket_issued', 'Ticket R-007 [Registrar] ERT:5min', '2026-10-19 12:40:41'),
(28, 2, 'ticket_called', 'Ticket R-007 [Registrar] called to window 1', '2026-10-19 12:41:10'),
(29, 2, 'ticket_served', 'Ticket R-007 served. Wait:0.48min', '2026-10-19 12:41:14'),
(30, 8, 'ticket_issued', 'Ticket R-008 [Registrar] ERT:5min', '2026-10-19 12:41:27'),
(31, 2, 'ticket_called', 'Ticket R-008 [Registrar] called to window 1', '2026-10-19 12:41:46'),
(32, 2, 'ticket_served', 'Ticket R-008 served. Wait:0.32min', '2026-10-19 12:41:49'),
(33, 8, 'ticket_issued', 'Ticket R-009 [Registrar] ERT:5min', '2026-10-19 12:42:02'),
(34, 2, 'ticket_called', 'Ticket R-009 [Registrar] called to window 1', '2026-10-19 12:42:12'),
(35, 2, 'ticket_served', 'Ticket R-009 served. Wait:0.17min', '2026-10-19 12:42:19'),
(36, 8, 'ticket_issued', 'Ticket R-010 [Registrar] ERT:5min', '2026-10-19 12:42:31'),
(37, 2, 'ticket_called', 'Ticket R-010 [Registrar] called to window 1', '2026-10-19 12:42:47'),
(38, 2, 'ticket_served', 'Ticket R-010 served. Wait:0.27min', '2026-10-19 12:42:52'),
(39, 1, 'login', 'User logged in', '2026-10-28 03:09:54'),
(40, 2, 'login', 'User logged in', '2026-10-28 03:11:11'),
(41, 4, 'ticket_issued', 'Ticket R-001 [Registrar] ERT:5min', '2026-10-28 03:14:28'),
(42, 2, 'ticket_called', 'Ticket R-001 [Registrar] called to window 1', '2026-10-28 03:14:43'),
(43, 2, 'ticket_served', 'Ticket R-001 served. Wait:0.25min', '2026-10-28 03:14:46'),
(44, 2, 'window_pause', 'Auto-skip PAUSED for window \'Window 1\'.', '2026-10-28 03:14:50'),
(45, 9, 'register', 'Student registered ID:2023-07-00475 Name:Jobert F. Del Valle', '2026-10-28 03:15:13'),
(46, 9, 'login', 'User logged in', '2026-10-28 03:15:18'),
(47, 9, 'ticket_issued', 'Ticket R-002 [Registrar] ERT:5min', '2026-10-28 03:15:26'),
(48, 8, 'ticket_issued', 'Ticket R-003 [Registrar] ERT:7.5min', '2026-10-28 03:16:24'),
(49, 10, 'register', 'Student registered ID:2027-01-00001 Name:Mikha Lim', '2026-10-28 03:16:59'),
(50, 10, 'login', 'User logged in', '2026-10-28 03:17:17'),
(51, 10, 'ticket_issued', 'Ticket R-004 [Registrar] ERT:10min', '2026-10-28 03:17:24'),
(52, 1, 'login', 'User logged in', '2026-10-28 03:18:34'),
(53, 2, 'ticket_called', 'Ticket R-002 [Registrar] called to window 1', '2026-10-28 03:23:01'),
(54, 2, 'ticket_served', 'Ticket R-002 served. Wait:7.58min', '2026-10-28 03:24:27'),
(55, 2, 'ticket_called', 'Ticket R-003 [Registrar] called to window 1', '2026-10-28 03:25:28'),
(56, 2, 'ticket_served', 'Ticket R-003 served. Wait:9.07min', '2026-10-28 03:25:32'),
(57, 2, 'ticket_called', 'Ticket R-004 [Registrar] called to window 1', '2026-10-28 03:25:36'),
(58, 2, 'ticket_served', 'Ticket R-004 served. Wait:8.2min', '2026-10-28 03:25:41'),
(59, 1, 'login', 'User logged in', '2026-10-28 03:26:27'),
(60, 1, 'login', 'User logged in', '2026-10-28 03:29:24'),
(61, 2, 'login', 'User logged in', '2026-10-28 04:05:07'),
(62, 9, 'ticket_issued', 'Ticket R-005 [Registrar] ERT:5min', '2026-10-28 04:18:42'),
(63, 4, 'ticket_issued', 'Ticket R-006 [Registrar] ERT:7.5min', '2026-10-28 04:20:41'),
(64, 8, 'ticket_issued', 'Ticket R-007 [Registrar] ERT:10min', '2026-10-28 04:20:53'),
(65, 2, 'ticket_called', 'Ticket R-005 [Registrar] called to window 1', '2026-10-28 04:21:42'),
(66, 2, 'ticket_served', 'Ticket R-005 served. Wait:3min', '2026-10-28 04:21:46'),
(67, 2, 'ticket_called', 'Ticket R-006 [Registrar] called to window 1', '2026-10-28 04:21:50'),
(68, 2, 'ticket_served', 'Ticket R-006 served. Wait:1.15min', '2026-10-28 04:21:53'),
(69, 2, 'ticket_called', 'Ticket R-007 [Registrar] called to window 1', '2026-10-28 04:21:56'),
(70, 2, 'ticket_served', 'Ticket R-007 served. Wait:1.05min', '2026-10-28 04:22:00'),
(71, 4, 'ticket_issued', 'Ticket R-008 [Registrar] ERT:5min', '2026-10-28 04:22:17'),
(72, 9, 'ticket_issued', 'Ticket R-009 [Registrar] ERT:7.5min', '2026-10-28 04:22:20'),
(73, 2, 'ticket_called', 'Ticket R-008 [Registrar] called to window 1', '2026-10-28 04:22:41'),
(74, 2, 'ticket_served', 'Ticket R-008 served. Wait:0.4min', '2026-10-28 04:22:45'),
(75, 2, 'ticket_called', 'Ticket R-009 [Registrar] called to window 1', '2026-10-28 04:22:48'),
(76, 2, 'ticket_served', 'Ticket R-009 served. Wait:0.47min', '2026-10-28 04:22:50'),
(77, 4, 'ticket_issued', 'Ticket R-010 [Registrar] ERT:5min', '2026-10-28 04:23:11'),
(78, 9, 'ticket_issued', 'Ticket R-011 [Registrar] ERT:6.4min', '2026-10-28 04:23:13'),
(79, 8, 'ticket_issued', 'Ticket R-012 [Registrar] ERT:11.2min', '2026-10-28 04:23:33'),
(80, 10, 'pwd_applied', 'Student submitted PWD ID for verification.', '2026-10-28 04:23:56'),
(81, 1, 'pwd_verified', 'PWD verified for Mikha Lim (2027-01-00001) by admin.', '2026-10-28 04:24:33'),
(82, 10, 'ticket_issued', 'Ticket R-013 [Registrar] ERT:14.1min', '2026-10-28 04:25:09'),
(83, 10, 'ticket_skipped', 'Ticket R-013 skipped attempt 1/3 — moved after next ticket.', '2026-10-28 04:25:54'),
(84, 10, 'ticket_skipped', 'Ticket R-013 skipped attempt 2/3 — moved after next ticket.', '2026-10-28 04:26:13'),
(85, 2, 'ticket_called', 'Ticket R-010 [Registrar] called to window 1', '2026-10-28 04:27:03'),
(86, 2, 'ticket_served', 'Ticket R-010 served. Wait:3.87min', '2026-10-28 04:27:08'),
(87, 2, 'ticket_called', 'Ticket R-013 [Registrar] called to window 1', '2026-10-28 04:27:14'),
(88, 2, 'ticket_served', 'Ticket R-013 served. Wait:4.03min', '2026-10-28 04:27:33'),
(89, 2, 'ticket_called', 'Ticket R-011 [Registrar] called to window 1', '2026-10-28 04:27:42'),
(90, 2, 'ticket_served', 'Ticket R-011 served. Wait:4.48min', '2026-10-28 04:27:45'),
(91, 2, 'ticket_served', 'Ticket R-011 served. Wait:4.48min', '2026-10-28 04:28:00'),
(92, 2, 'ticket_served', 'Ticket R-011 served. Wait:4.48min', '2026-10-28 04:29:04'),
(93, 2, 'ticket_served', 'Ticket R-011 served. Wait:4.48min', '2026-10-28 04:29:06'),
(94, 2, 'ticket_served', 'Ticket R-011 served. Wait:4.48min', '2026-10-28 04:29:06'),
(95, 2, 'ticket_served', 'Ticket R-011 served. Wait:4.48min', '2026-10-28 04:29:06'),
(96, 2, 'ticket_served', 'Ticket R-011 served. Wait:4.48min', '2026-10-28 04:29:06'),
(97, 2, 'ticket_served', 'Ticket R-011 served. Wait:4.48min', '2026-10-28 04:29:08'),
(98, 2, 'ticket_served', 'Ticket R-011 served. Wait:4.48min', '2026-10-28 04:29:10'),
(99, 2, 'ticket_served', 'Ticket R-011 served. Wait:4.48min', '2026-10-28 04:29:10'),
(100, 2, 'ticket_served', 'Ticket R-011 served. Wait:4.48min', '2026-10-28 04:29:10'),
(101, 2, 'ticket_served', 'Ticket R-011 served. Wait:4.48min', '2026-10-28 04:29:10'),
(102, 2, 'ticket_served', 'Ticket R-011 served. Wait:4.48min', '2026-10-28 04:29:10'),
(103, 2, 'ticket_served', 'Ticket R-011 served. Wait:4.48min', '2026-10-28 04:29:10'),
(104, 2, 'ticket_served', 'Ticket R-011 served. Wait:4.48min', '2026-10-28 04:29:10'),
(105, 2, 'ticket_called', 'Ticket R-012 [Registrar] called to window 1', '2026-10-28 04:29:36'),
(106, 2, 'ticket_served', 'Ticket R-012 served. Wait:6.05min', '2026-10-28 04:29:39'),
(107, 9, 'ticket_issued', 'Ticket R-014 [Registrar] ERT:5min', '2026-10-28 04:30:13'),
(108, 10, 'ticket_issued', 'Ticket R-015 [Registrar] ERT:7.5min', '2026-10-28 04:30:34'),
(109, 4, 'ticket_issued', 'Ticket R-016 [Registrar] ERT:11.2min', '2026-10-28 04:30:45'),
(110, 2, 'ticket_called', 'Ticket R-014 [Registrar] called to window 1', '2026-10-28 04:30:58'),
(111, 2, 'ticket_served', 'Ticket R-014 served. Wait:0.75min', '2026-10-28 04:31:02'),
(112, 8, 'ticket_issued', 'Ticket R-017 [Registrar] ERT:10min', '2026-10-28 04:31:04'),
(113, 2, 'ticket_served', 'Ticket R-014 served. Wait:0.75min', '2026-10-28 04:31:06'),
(114, 2, 'ticket_served', 'Ticket R-014 served. Wait:0.75min', '2026-10-28 04:31:07'),
(115, 2, 'ticket_called', 'Ticket R-015 [Registrar] called to window 1', '2026-10-28 04:31:10'),
(116, 2, 'ticket_called', 'Ticket R-015 [Registrar] called to window 1', '2026-10-28 04:31:11'),
(117, 2, 'ticket_called', 'Ticket R-016 [Registrar] called to window 1', '2026-10-28 04:31:11'),
(118, 2, 'ticket_called', 'Ticket R-016 [Registrar] called to window 1', '2026-10-28 04:31:12'),
(119, 2, 'ticket_called', 'Ticket R-017 [Registrar] called to window 1', '2026-10-28 04:31:14'),
(120, 2, 'ticket_called', 'Ticket R-017 [Registrar] called to window 1', '2026-10-28 04:31:18'),
(121, 2, 'ticket_served', 'Ticket R-015 served. Wait:0.62min', '2026-10-28 04:31:18'),
(122, 2, 'ticket_called', 'Ticket R-017 [Registrar] called to window 1', '2026-10-28 04:31:21'),
(123, 2, 'ticket_served', 'Ticket R-015 served. Wait:0.62min', '2026-10-28 04:31:22'),
(124, 2, 'ticket_served', 'Ticket R-016 served. Wait:0.45min', '2026-10-28 04:31:28'),
(125, 2, 'ticket_served', 'Ticket R-016 served. Wait:0.45min', '2026-10-28 04:31:29'),
(126, 2, 'ticket_served', 'Ticket R-017 served. Wait:0.28min', '2026-10-28 04:31:46'),
(127, 1, 'login', 'User logged in', '2026-10-28 06:02:25'),
(128, 2, 'login', 'User logged in', '2026-10-28 06:05:49'),
(129, 9, 'ticket_issued', 'Ticket R-018 [Registrar] ERT:5min', '2026-10-28 06:06:25'),
(130, 10, 'ticket_issued', 'Ticket RP-001 [Registrar] PRIORITY(PWD) ERT:5min', '2026-10-28 06:06:29'),
(131, 8, 'ticket_skipped', 'Ticket R-017 skipped attempt 1/3 — moved after next ticket.', '2026-10-28 06:07:15'),
(132, 8, 'ticket_skipped', 'Ticket R-017 skipped attempt 2/3 — moved after next ticket.', '2026-10-28 06:07:20'),
(133, 2, 'ticket_called', 'Ticket RP-001 [Registrar] called to window 1', '2026-10-28 06:15:14'),
(134, 2, 'ticket_served', 'Ticket RP-001 served. Wait:8.75min', '2026-10-28 06:15:18'),
(135, 2, 'ticket_called', 'Ticket R-018 [Registrar] called to window 1', '2026-10-28 06:15:20'),
(136, 2, 'ticket_served', 'Ticket R-018 served. Wait:8.92min', '2026-10-28 06:15:26'),
(137, 2, 'ticket_called', 'Ticket R-017 [Registrar] called to window 1', '2026-10-28 06:15:30'),
(138, 2, 'ticket_served', 'Ticket R-017 served. Wait:9.07min', '2026-10-28 06:15:37'),
(139, 2, 'login', 'User logged in', '2026-10-28 06:15:54'),
(140, 10, 'login', 'User logged in', '2026-10-28 06:32:21'),
(141, 8, 'ticket_issued', 'Ticket R-020 [Registrar] ERT:5min', '2026-10-28 06:32:51'),
(142, 2, 'login', 'User logged in', '2026-10-28 06:32:53'),
(143, 11, 'register', 'Student registered ID:2017-05-07116 Name:John Carlo Magtoto', '2026-10-28 06:34:07'),
(144, 11, 'login', 'User logged in', '2026-10-28 06:34:11'),
(145, 11, 'ticket_issued', 'Ticket R-021 [Registrar] ERT:7.5min', '2026-10-28 06:35:48'),
(146, 9, 'login', 'User logged in', '2026-10-28 06:36:59'),
(147, 9, 'ticket_issued', 'Ticket R-022 [Registrar] ERT:10min', '2026-10-28 06:37:12'),
(148, 10, 'ticket_issued', 'Ticket RP-002 [Registrar] PRIORITY(PWD) ERT:5min', '2026-10-28 06:37:26'),
(149, 2, 'ticket_called', 'Ticket RP-002 [Registrar] called to window 1', '2026-10-28 06:41:01'),
(150, 2, 'ticket_served', 'Ticket RP-002 served. Wait:3.58min', '2026-10-28 06:41:04'),
(151, 2, 'ticket_called', 'Ticket R-020 [Registrar] called to window 1', '2026-10-28 06:41:07'),
(152, 2, 'ticket_called', 'Ticket R-021 [Registrar] called to window 1', '2026-10-28 06:41:08'),
(153, 2, 'ticket_served', 'Ticket R-020 served. Wait:8.27min', '2026-10-28 06:41:11'),
(154, 2, 'ticket_served', 'Ticket R-021 served. Wait:5.33min', '2026-10-28 06:41:18'),
(155, 2, 'ticket_called', 'Ticket R-022 [Registrar] called to window 1', '2026-10-28 06:41:21'),
(156, 2, 'ticket_served', 'Ticket R-022 served. Wait:4.15min', '2026-10-28 06:41:25'),
(157, 1, 'login', 'User logged in', '2026-10-28 06:41:44');

-- --------------------------------------------------------

--
-- Table structure for table `cashier_transactions`
--

CREATE TABLE `cashier_transactions` (
  `id` int(11) NOT NULL,
  `student_name` varchar(100) NOT NULL,
  `student_id` varchar(50) DEFAULT NULL,
  `purpose` varchar(200) NOT NULL,
  `amount` decimal(10,2) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `processed_by` int(11) DEFAULT NULL,
  `transaction_date` date NOT NULL DEFAULT curdate(),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `historical_data`
--

CREATE TABLE `historical_data` (
  `record_id` int(11) NOT NULL,
  `ticket_id` int(11) NOT NULL,
  `actual_wait_time` decimal(8,2) NOT NULL,
  `actual_service_time` decimal(8,2) NOT NULL,
  `transaction_type` varchar(50) NOT NULL,
  `queue_length_at_issue` int(11) NOT NULL,
  `time_of_day` tinyint(4) NOT NULL,
  `day_of_week` tinyint(4) NOT NULL,
  `windows_open_count` tinyint(4) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `historical_data`
--

INSERT INTO `historical_data` (`record_id`, `ticket_id`, `actual_wait_time`, `actual_service_time`, `transaction_type`, `queue_length_at_issue`, `time_of_day`, `day_of_week`, `windows_open_count`, `created_at`) VALUES
(1, 3, 0.63, 0.12, 'Registrar', 1, 20, 0, 2, '2026-10-19 12:37:56'),
(2, 4, 0.32, 0.03, 'Registrar', 2, 20, 0, 2, '2026-10-19 12:38:35'),
(3, 5, 0.20, 0.03, 'Registrar', 3, 20, 0, 2, '2026-10-19 12:39:06'),
(4, 6, 0.33, 0.03, 'Registrar', 4, 20, 0, 2, '2026-10-19 12:39:47'),
(5, 7, 0.18, 0.05, 'Registrar', 5, 20, 0, 2, '2026-10-19 12:40:11'),
(6, 8, 0.12, 0.03, 'Registrar', 6, 20, 0, 2, '2026-10-19 12:40:31'),
(7, 9, 0.48, 0.07, 'Registrar', 7, 20, 0, 2, '2026-10-19 12:41:14'),
(8, 10, 0.32, 0.05, 'Registrar', 8, 20, 0, 2, '2026-10-19 12:41:49'),
(9, 11, 0.17, 0.12, 'Registrar', 9, 20, 0, 2, '2026-10-19 12:42:19'),
(10, 12, 0.27, 0.08, 'Registrar', 10, 20, 0, 2, '2026-10-19 12:42:52'),
(11, 14, 0.25, 0.05, 'Registrar', 11, 11, 2, 2, '2026-10-28 03:14:46'),
(12, 15, 7.58, 1.43, 'Registrar', 14, 11, 2, 2, '2026-10-28 03:24:27'),
(13, 16, 9.07, 0.07, 'Registrar', 14, 11, 2, 2, '2026-10-28 03:25:32'),
(14, 17, 8.20, 0.08, 'Registrar', 14, 11, 2, 2, '2026-10-28 03:25:41'),
(15, 18, 3.00, 0.07, 'Registrar', 17, 12, 2, 2, '2026-10-28 04:21:46'),
(16, 19, 1.15, 0.05, 'Registrar', 17, 12, 2, 2, '2026-10-28 04:21:53'),
(17, 20, 1.05, 0.07, 'Registrar', 17, 12, 2, 2, '2026-10-28 04:22:00'),
(18, 21, 0.40, 0.07, 'Registrar', 19, 12, 2, 2, '2026-10-28 04:22:45'),
(19, 22, 0.47, 0.03, 'Registrar', 19, 12, 2, 2, '2026-10-28 04:22:50'),
(20, 23, 3.87, 0.08, 'Registrar', 23, 12, 2, 2, '2026-10-28 04:27:08'),
(21, 26, 4.03, 0.32, 'Registrar', 23, 12, 2, 2, '2026-10-28 04:27:33'),
(22, 24, 4.48, 0.05, 'Registrar', 23, 12, 2, 2, '2026-10-28 04:27:45'),
(23, 24, 4.48, 0.30, 'Registrar', 23, 12, 2, 2, '2026-10-28 04:28:00'),
(24, 24, 4.48, 1.37, 'Registrar', 23, 12, 2, 2, '2026-10-28 04:29:04'),
(25, 24, 4.48, 1.40, 'Registrar', 23, 12, 2, 2, '2026-10-28 04:29:06'),
(26, 24, 4.48, 1.40, 'Registrar', 23, 12, 2, 2, '2026-10-28 04:29:06'),
(27, 24, 4.48, 1.40, 'Registrar', 23, 12, 2, 2, '2026-10-28 04:29:06'),
(28, 24, 4.48, 1.40, 'Registrar', 23, 12, 2, 2, '2026-10-28 04:29:06'),
(29, 24, 4.48, 1.43, 'Registrar', 23, 12, 2, 2, '2026-10-28 04:29:08'),
(30, 24, 4.48, 1.47, 'Registrar', 23, 12, 2, 2, '2026-10-28 04:29:10'),
(31, 24, 4.48, 1.47, 'Registrar', 23, 12, 2, 2, '2026-10-28 04:29:10'),
(32, 24, 4.48, 1.47, 'Registrar', 23, 12, 2, 2, '2026-10-28 04:29:10'),
(33, 24, 4.48, 1.47, 'Registrar', 23, 12, 2, 2, '2026-10-28 04:29:10'),
(34, 24, 4.48, 1.47, 'Registrar', 23, 12, 2, 2, '2026-10-28 04:29:10'),
(35, 24, 4.48, 1.47, 'Registrar', 23, 12, 2, 2, '2026-10-28 04:29:10'),
(36, 24, 4.48, 1.47, 'Registrar', 23, 12, 2, 2, '2026-10-28 04:29:10'),
(37, 25, 6.05, 0.05, 'Registrar', 23, 12, 2, 2, '2026-10-28 04:29:39'),
(38, 27, 0.75, 0.07, 'Registrar', 26, 12, 2, 2, '2026-10-28 04:31:02'),
(39, 27, 0.75, 0.13, 'Registrar', 27, 12, 2, 2, '2026-10-28 04:31:06'),
(40, 27, 0.75, 0.15, 'Registrar', 27, 12, 2, 2, '2026-10-28 04:31:07'),
(41, 28, 0.62, 0.12, 'Registrar', 27, 12, 2, 2, '2026-10-28 04:31:18'),
(42, 28, 0.62, 0.18, 'Registrar', 27, 12, 2, 2, '2026-10-28 04:31:22'),
(43, 29, 0.45, 0.27, 'Registrar', 27, 12, 2, 2, '2026-10-28 04:31:28'),
(44, 29, 0.45, 0.28, 'Registrar', 27, 12, 2, 2, '2026-10-28 04:31:29'),
(45, 30, 0.28, 0.42, 'Registrar', 27, 12, 2, 2, '2026-10-28 04:31:46'),
(46, 32, 8.75, 0.07, 'Registrar', 29, 14, 2, 2, '2026-10-28 06:15:18'),
(47, 31, 8.92, 0.10, 'Registrar', 29, 14, 2, 2, '2026-10-28 06:15:26'),
(48, 30, 9.07, 0.12, 'Registrar', 29, 14, 2, 2, '2026-10-28 06:15:37'),
(49, 36, 3.58, 0.05, 'Registrar', 33, 14, 2, 2, '2026-10-28 06:41:04'),
(50, 33, 8.27, 0.07, 'Registrar', 33, 14, 2, 2, '2026-10-28 06:41:11'),
(51, 34, 5.33, 0.17, 'Registrar', 33, 14, 2, 2, '2026-10-28 06:41:18'),
(52, 35, 4.15, 0.07, 'Registrar', 33, 14, 2, 2, '2026-10-28 06:41:25');

-- --------------------------------------------------------

--
-- Table structure for table `queue_tickets`
--

CREATE TABLE `queue_tickets` (
  `ticket_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `ticket_number` varchar(20) NOT NULL,
  `service_type` enum('Registrar','Cashier','OSA') NOT NULL,
  `source` enum('mobile','kiosk') NOT NULL DEFAULT 'mobile',
  `walkin_name` varchar(100) DEFAULT NULL,
  `walkin_id` varchar(30) DEFAULT NULL,
  `year_section` varchar(50) DEFAULT NULL,
  `purpose` varchar(200) DEFAULT NULL,
  `window_id` int(11) DEFAULT NULL,
  `issued_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `called_at` timestamp NULL DEFAULT NULL,
  `served_at` timestamp NULL DEFAULT NULL,
  `status` enum('Waiting','Serving','Served','Skipped') NOT NULL DEFAULT 'Waiting',
  `predicted_ert` decimal(8,2) DEFAULT NULL,
  `skip_count` tinyint(4) NOT NULL DEFAULT 0,
  `is_priority` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `queue_tickets`
--

INSERT INTO `queue_tickets` (`ticket_id`, `user_id`, `ticket_number`, `service_type`, `source`, `walkin_name`, `walkin_id`, `year_section`, `purpose`, `window_id`, `issued_at`, `called_at`, `served_at`, `status`, `predicted_ert`, `skip_count`, `is_priority`) VALUES
(3, 8, 'R-001', 'Registrar', 'mobile', NULL, NULL, '', 'Enrollment', 1, '2026-10-19 12:37:11', '2026-10-19 12:37:49', '2026-10-19 12:37:56', 'Served', 5.00, 0, 0),
(4, 8, 'R-002', 'Registrar', 'mobile', NULL, NULL, '', 'Grade Slip', 1, '2026-10-19 12:38:14', '2026-10-19 12:38:33', '2026-10-19 12:38:35', 'Served', 5.00, 0, 0),
(5, 8, 'R-003', 'Registrar', 'mobile', NULL, NULL, '', 'Certificate of Enrollment', 1, '2026-10-19 12:38:52', '2026-10-19 12:39:04', '2026-10-19 12:39:06', 'Served', 5.00, 0, 0),
(6, 8, 'R-004', 'Registrar', 'mobile', NULL, NULL, '', 'Transcript of Records', 1, '2026-10-19 12:39:25', '2026-10-19 12:39:45', '2026-10-19 12:39:47', 'Served', 5.00, 0, 0),
(7, 8, 'R-005', 'Registrar', 'mobile', NULL, NULL, '', 'Good Moral Certificate', 1, '2026-10-19 12:39:57', '2026-10-19 12:40:08', '2026-10-19 12:40:11', 'Served', 5.00, 0, 0),
(8, 8, 'R-006', 'Registrar', 'mobile', NULL, NULL, '', 'Document Request', 1, '2026-10-19 12:40:22', '2026-10-19 12:40:29', '2026-10-19 12:40:31', 'Served', 5.00, 0, 0),
(9, 8, 'R-007', 'Registrar', 'mobile', NULL, NULL, '', 'Records Verification', 1, '2026-10-19 12:40:41', '2026-10-19 12:41:10', '2026-10-19 12:41:14', 'Served', 5.00, 0, 0),
(10, 8, 'R-008', 'Registrar', 'mobile', NULL, NULL, '', 'Enrollment', 1, '2026-10-19 12:41:27', '2026-10-19 12:41:46', '2026-10-19 12:41:49', 'Served', 5.00, 0, 0),
(11, 8, 'R-009', 'Registrar', 'mobile', NULL, NULL, '', 'Grade Slip', 1, '2026-10-19 12:42:02', '2026-10-19 12:42:12', '2026-10-19 12:42:19', 'Served', 5.00, 0, 0),
(12, 8, 'R-010', 'Registrar', 'mobile', NULL, NULL, '', 'Transcript of Records', 1, '2026-10-19 12:42:31', '2026-10-19 12:42:47', '2026-10-19 12:42:52', 'Served', 5.00, 0, 0),
(14, 4, 'R-001', 'Registrar', 'mobile', NULL, NULL, '', 'Enrollment', 1, '2026-10-28 03:14:28', '2026-10-28 03:14:43', '2026-10-28 03:14:46', 'Served', 5.00, 0, 0),
(15, 9, 'R-002', 'Registrar', 'mobile', NULL, NULL, '', 'Enrollment', 1, '2026-10-28 03:15:26', '2026-10-28 03:23:01', '2026-10-28 03:24:27', 'Served', 5.00, 0, 0),
(16, 8, 'R-003', 'Registrar', 'mobile', NULL, NULL, '', 'Enrollment', 1, '2026-10-28 03:16:24', '2026-10-28 03:25:28', '2026-10-28 03:25:31', 'Served', 3.60, 0, 0),
(17, 10, 'R-004', 'Registrar', 'mobile', NULL, NULL, '', 'Grade Slip', 1, '2026-10-28 03:17:24', '2026-10-28 03:25:36', '2026-10-28 03:25:41', 'Served', 5.00, 0, 0),
(18, 9, 'R-005', 'Registrar', 'mobile', NULL, NULL, '', 'Enrollment', 1, '2026-10-28 04:18:42', '2026-10-28 04:21:42', '2026-10-28 04:21:46', 'Served', 5.00, 0, 0),
(19, 4, 'R-006', 'Registrar', 'mobile', NULL, NULL, '', 'Document Request', 1, '2026-10-28 04:20:41', '2026-10-28 04:21:50', '2026-10-28 04:21:53', 'Served', 5.00, 0, 0),
(20, 8, 'R-007', 'Registrar', 'mobile', NULL, NULL, '', 'Transcript of Records', 1, '2026-10-28 04:20:53', '2026-10-28 04:21:56', '2026-10-28 04:22:00', 'Served', 5.00, 0, 0),
(21, 4, 'R-008', 'Registrar', 'mobile', NULL, NULL, '', 'Certificate of Enrollment', 1, '2026-10-28 04:22:17', '2026-10-28 04:22:41', '2026-10-28 04:22:45', 'Served', 5.00, 0, 0),
(22, 9, 'R-009', 'Registrar', 'mobile', NULL, NULL, '', 'Enrollment', 1, '2026-10-28 04:22:20', '2026-10-28 04:22:48', '2026-10-28 04:22:50', 'Served', 4.90, 0, 0),
(23, 4, 'R-010', 'Registrar', 'mobile', NULL, NULL, '', 'Grade Slip', 1, '2026-10-28 04:23:11', '2026-10-28 04:27:03', '2026-10-28 04:27:08', 'Served', 5.00, 0, 0),
(24, 9, 'R-011', 'Registrar', 'mobile', NULL, NULL, '', 'Enrollment', 1, '2026-10-28 04:23:13', '2026-10-28 04:27:42', '2026-10-28 04:29:10', 'Served', 4.70, 0, 0),
(25, 8, 'R-012', 'Registrar', 'mobile', NULL, NULL, '', 'Enrollment', 1, '2026-10-28 04:23:33', '2026-10-28 04:29:36', '2026-10-28 04:29:39', 'Served', 5.00, 0, 0),
(26, 10, 'R-013', 'Registrar', 'mobile', NULL, NULL, '', 'Enrollment', 1, '2026-10-28 04:23:12', '2026-10-28 04:27:14', '2026-10-28 04:27:33', 'Served', 4.90, 2, 0),
(27, 9, 'R-014', 'Registrar', 'mobile', NULL, NULL, '', 'Enrollment', 1, '2026-10-28 04:30:13', '2026-10-28 04:30:58', '2026-10-28 04:31:07', 'Served', 5.00, 0, 0),
(28, 10, 'R-015', 'Registrar', 'mobile', NULL, NULL, '', 'Enrollment', 1, '2026-10-28 04:30:34', '2026-10-28 04:31:11', '2026-10-28 04:31:22', 'Served', 4.90, 0, 0),
(29, 4, 'R-016', 'Registrar', 'mobile', NULL, NULL, '', 'Grade Slip', 1, '2026-10-28 04:30:45', '2026-10-28 04:31:12', '2026-10-28 04:31:29', 'Served', 5.00, 0, 0),
(30, 8, 'R-017', 'Registrar', 'mobile', NULL, NULL, '', 'Certificate of Enrollment', 1, '2026-10-28 06:06:26', '2026-10-28 06:15:30', '2026-10-28 06:15:37', 'Served', 4.90, 2, 0),
(31, 9, 'R-018', 'Registrar', 'mobile', NULL, NULL, '', 'Enrollment', 1, '2026-10-28 06:06:25', '2026-10-28 06:15:20', '2026-10-28 06:15:26', 'Served', 5.00, 0, 0),
(32, 10, 'RP-001', 'Registrar', 'mobile', NULL, NULL, '', 'Enrollment', 1, '2026-10-28 06:06:29', '2026-10-28 06:15:14', '2026-10-28 06:15:17', 'Served', 5.00, 0, 1),
(33, 8, 'R-020', 'Registrar', 'mobile', NULL, NULL, '', 'Transcript of Records', 1, '2026-10-28 06:32:51', '2026-10-28 06:41:07', '2026-10-28 06:41:11', 'Served', 5.00, 0, 0),
(34, 11, 'R-021', 'Registrar', 'mobile', NULL, NULL, '', 'Enrollment', 1, '2026-10-28 06:35:48', '2026-10-28 06:41:08', '2026-10-28 06:41:18', 'Served', 5.00, 0, 0),
(35, 9, 'R-022', 'Registrar', 'mobile', NULL, NULL, '', 'Enrollment', 1, '2026-10-28 06:37:12', '2026-10-28 06:41:21', '2026-10-28 06:41:25', 'Served', 5.00, 0, 0),
(36, 10, 'RP-002', 'Registrar', 'mobile', NULL, NULL, '', 'Enrollment', 1, '2026-10-28 06:37:26', '2026-10-28 06:41:01', '2026-10-28 06:41:04', 'Served', 5.00, 0, 1);

-- --------------------------------------------------------

--
-- Table structure for table `service_windows`
--

CREATE TABLE `service_windows` (
  `window_id` int(11) NOT NULL,
  `window_name` varchar(50) NOT NULL,
  `service_type` enum('Registrar','Cashier','OSA') NOT NULL,
  `assigned_staff_id` int(11) DEFAULT NULL,
  `is_open` tinyint(1) NOT NULL DEFAULT 0,
  `skip_paused` tinyint(1) NOT NULL DEFAULT 0,
  `queue_paused` tinyint(1) NOT NULL DEFAULT 0,
  `mod_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `mod_by` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `service_windows`
--

INSERT INTO `service_windows` (`window_id`, `window_name`, `service_type`, `assigned_staff_id`, `is_open`, `skip_paused`, `queue_paused`, `mod_at`, `mod_by`) VALUES
(1, 'Window 1', 'Registrar', 2, 1, 1, 0, '2026-10-28 03:14:50', NULL),
(2, 'Window 2', 'Registrar', 5, 1, 0, 0, '2026-10-19 12:23:27', NULL),
(3, 'Window 1', 'Cashier', 3, 1, 0, 0, '2026-10-19 12:23:27', NULL),
(4, 'Window 2', 'Cashier', 6, 1, 0, 0, '2026-10-19 12:23:27', NULL),
(5, 'Window 1', 'OSA', 4, 1, 0, 0, '2026-10-19 12:23:27', NULL),
(6, 'Window 2', 'OSA', 7, 1, 0, 0, '2026-10-19 12:23:27', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `system_settings`
--

CREATE TABLE `system_settings` (
  `setting_id` int(11) NOT NULL,
  `setting_key` varchar(100) NOT NULL,
  `setting_value` varchar(255) DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `system_settings`
--

INSERT INTO `system_settings` (`setting_id`, `setting_key`, `setting_value`, `updated_by`, `updated_at`) VALUES
(1, 'base_time_Registrar', '5', 1, '2026-10-19 12:35:07'),
(2, 'base_time_Cashier', '5', 1, '2026-10-19 12:35:08'),
(3, 'base_time_OSA', '3', 1, '2026-10-19 12:35:09');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `user_id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `full_name` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `role` enum('Admin','Staff','Student') NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `pwd_status` varchar(12) NOT NULL DEFAULT 'none',
  `pwd_id_number` varchar(40) DEFAULT NULL,
  `pwd_id_photo` varchar(120) DEFAULT NULL,
  `pwd_reject_reason` varchar(255) DEFAULT NULL,
  `pwd_verified_by` int(11) DEFAULT NULL,
  `pwd_verified_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`user_id`, `username`, `password_hash`, `full_name`, `email`, `role`, `is_active`, `created_at`, `pwd_status`, `pwd_id_number`, `pwd_id_photo`, `pwd_reject_reason`, `pwd_verified_by`, `pwd_verified_at`) VALUES
(1, 'admin', '$2y$10$Uv.paWKTb5SN8caUw786wu6ba3T6u8aS0eFZiMTjpB.BHK1vYi/2G', 'System Administrator', 'admin@grc.edu.ph', 'Admin', 1, '2026-10-19 12:23:27', 'none', NULL, NULL, NULL, NULL, NULL),
(2, 'staff1', '$2y$10$tw3LuElFuCebuNalTsOW7OOcfBmphLXsNKfoA7xr75rx0pvQiOkwW', 'staff 1', 'staff1@grc.edu.ph', 'Staff', 1, '2026-10-19 12:23:27', 'none', NULL, NULL, NULL, NULL, NULL),
(3, 'staff2', '$2y$10$tw3LuElFuCebuNalTsOW7OOcfBmphLXsNKfoA7xr75rx0pvQiOkwW', 'staff 2', 'staff2@grc.edu.ph', 'Staff', 1, '2026-10-19 12:23:27', 'none', NULL, NULL, NULL, NULL, NULL),
(4, 'staff3', '$2y$10$tw3LuElFuCebuNalTsOW7OOcfBmphLXsNKfoA7xr75rx0pvQiOkwW', 'staff 3', 'staff3@grc.edu.ph', 'Staff', 1, '2026-10-19 12:23:27', 'none', NULL, NULL, NULL, NULL, NULL),
(5, 'staff4', '$2y$10$tw3LuElFuCebuNalTsOW7OOcfBmphLXsNKfoA7xr75rx0pvQiOkwW', 'staff 4', 'staff4@grc.edu.ph', 'Staff', 1, '2026-10-19 12:23:27', 'none', NULL, NULL, NULL, NULL, NULL),
(6, 'staff5', '$2y$10$tw3LuElFuCebuNalTsOW7OOcfBmphLXsNKfoA7xr75rx0pvQiOkwW', 'staff 5', 'staff5@grc.edu.ph', 'Staff', 1, '2026-10-19 12:23:27', 'none', NULL, NULL, NULL, NULL, NULL),
(7, 'staff6', '$2y$10$tw3LuElFuCebuNalTsOW7OOcfBmphLXsNKfoA7xr75rx0pvQiOkwW', 'staff 6', 'staff6@grc.edu.ph', 'Staff', 1, '2026-10-19 12:23:27', 'none', NULL, NULL, NULL, NULL, NULL),
(8, '2026-10-00022', '$2y$10$wCmRdzmjJ6nJNjIBRQFQVOhwsvVml9XMg3hqHum5yJMAKKWflXXQW', 'Rhayn Mercader', 'rhayn_merca1004@gmail.com', 'Student', 1, '2026-10-19 12:36:34', 'none', NULL, NULL, NULL, NULL, NULL),
(9, '2023-07-00475', '$2y$10$49wgXQl2Ri5Aw23Qnr6hd.YbuJJkgbVn077cMmeqp4maIEojtJbBq', 'Jobert F. Del Valle', 'delvallejobert2002@gmail.com', 'Student', 1, '2026-10-28 03:15:13', 'none', NULL, NULL, NULL, NULL, NULL),
(10, '2027-01-00001', '$2y$10$et/3mquPjQ0JEIOBzV.31.cgxLcqAszvzM0TRR5fI/72fdhjPRToy', 'Mikha Lim', 'mikha@gmail.com', 'Student', 1, '2026-10-28 03:16:59', 'verified', '12-1234-123-1234567', 'u10_1793161436.jpg', NULL, 1, '2026-10-28 12:24:33'),
(11, '2017-05-07116', '$2y$10$ITjYD7IA0mC05RJSqBnLPecxZ3j.Dec/3rAkVzttxlNnlkwTjrWiC', 'John Carlo Magtoto', 'kaynser2207@gmail.com', 'Student', 1, '2026-10-28 06:34:07', 'none', NULL, NULL, NULL, NULL, NULL);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `activity_logs`
--
ALTER TABLE `activity_logs`
  ADD PRIMARY KEY (`log_id`),
  ADD KEY `fk_al_user` (`user_id`);

--
-- Indexes for table `cashier_transactions`
--
ALTER TABLE `cashier_transactions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `fk_ct_user` (`processed_by`);

--
-- Indexes for table `historical_data`
--
ALTER TABLE `historical_data`
  ADD PRIMARY KEY (`record_id`),
  ADD KEY `fk_hd_ticket` (`ticket_id`);

--
-- Indexes for table `queue_tickets`
--
ALTER TABLE `queue_tickets`
  ADD PRIMARY KEY (`ticket_id`),
  ADD KEY `fk_qt_user` (`user_id`),
  ADD KEY `fk_qt_window` (`window_id`);

--
-- Indexes for table `service_windows`
--
ALTER TABLE `service_windows`
  ADD PRIMARY KEY (`window_id`),
  ADD KEY `fk_sw_staff` (`assigned_staff_id`),
  ADD KEY `fk_sw_mod` (`mod_by`);

--
-- Indexes for table `system_settings`
--
ALTER TABLE `system_settings`
  ADD PRIMARY KEY (`setting_id`),
  ADD UNIQUE KEY `setting_key` (`setting_key`),
  ADD KEY `fk_ss_user` (`updated_by`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `activity_logs`
--
ALTER TABLE `activity_logs`
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=158;

--
-- AUTO_INCREMENT for table `cashier_transactions`
--
ALTER TABLE `cashier_transactions`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `historical_data`
--
ALTER TABLE `historical_data`
  MODIFY `record_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=53;

--
-- AUTO_INCREMENT for table `queue_tickets`
--
ALTER TABLE `queue_tickets`
  MODIFY `ticket_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=37;

--
-- AUTO_INCREMENT for table `service_windows`
--
ALTER TABLE `service_windows`
  MODIFY `window_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `system_settings`
--
ALTER TABLE `system_settings`
  MODIFY `setting_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `activity_logs`
--
ALTER TABLE `activity_logs`
  ADD CONSTRAINT `fk_al_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `cashier_transactions`
--
ALTER TABLE `cashier_transactions`
  ADD CONSTRAINT `fk_ct_user` FOREIGN KEY (`processed_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

--
-- Constraints for table `historical_data`
--
ALTER TABLE `historical_data`
  ADD CONSTRAINT `fk_hd_ticket` FOREIGN KEY (`ticket_id`) REFERENCES `queue_tickets` (`ticket_id`) ON DELETE CASCADE;

--
-- Constraints for table `queue_tickets`
--
ALTER TABLE `queue_tickets`
  ADD CONSTRAINT `fk_qt_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_qt_window` FOREIGN KEY (`window_id`) REFERENCES `service_windows` (`window_id`) ON DELETE SET NULL;

--
-- Constraints for table `service_windows`
--
ALTER TABLE `service_windows`
  ADD CONSTRAINT `fk_sw_mod` FOREIGN KEY (`mod_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_sw_staff` FOREIGN KEY (`assigned_staff_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

--
-- Constraints for table `system_settings`
--
ALTER TABLE `system_settings`
  ADD CONSTRAINT `fk_ss_user` FOREIGN KEY (`updated_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
