CREATE TABLE `cryptos` (
  `name` varchar(40) NOT NULL,
  `label` varchar(255) NOT NULL,
  `value` double NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE `cryptos`
  ADD PRIMARY KEY (`name`);
COMMIT;

CREATE TABLE `cryptos_wallet` (
  `identifier` varchar(80) NOT NULL,
  `wallet` text NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

ALTER TABLE `cryptos_wallet`
  ADD PRIMARY KEY (`identifier`);
COMMIT;
