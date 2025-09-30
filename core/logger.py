import logging
import sys
import os
from datetime import datetime


class Logger:
    def __init__(self, log_dir, name="MART"):
        """
        Initialize logger that saves to both file and console

        Args:
            log_dir: Directory to save log files
            name: Logger name
        """
        self.log_dir = log_dir
        self.name = name

        # Create log directory if it doesn't exist
        os.makedirs(log_dir, exist_ok=True)

        # Create log filename with timestamp
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        log_filename = f"{name}_{timestamp}.log"
        self.log_file = os.path.join(log_dir, log_filename)

        # Setup logger
        self.logger = logging.getLogger(name)
        self.logger.setLevel(logging.INFO)

        # Remove existing handlers to avoid duplicates
        for handler in self.logger.handlers[:]:
            self.logger.removeHandler(handler)

        # Create formatters
        file_formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        console_formatter = logging.Formatter(
            '%(asctime)s - %(levelname)s - %(message)s'
        )

        # File handler
        file_handler = logging.FileHandler(self.log_file)
        file_handler.setLevel(logging.INFO)
        file_handler.setFormatter(file_formatter)
        self.logger.addHandler(file_handler)

        # Console handler
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setLevel(logging.INFO)
        console_handler.setFormatter(console_formatter)
        self.logger.addHandler(console_handler)

        self.info(f"Logger initialized. Log file: {self.log_file}")

    def info(self, message):
        self.logger.info(message)

    def warning(self, message):
        self.logger.warning(message)

    def error(self, message):
        self.logger.error(message)

    def debug(self, message):
        self.logger.debug(message)

    def critical(self, message):
        self.logger.critical(message)


class TeeLogger:
    """Redirect stdout and stderr to both file and console"""

    def __init__(self, log_file, stream):
        self.log_file = log_file
        self.stream = stream

    def write(self, message):
        self.stream.write(message)
        self.stream.flush()
        with open(self.log_file, 'a', encoding='utf-8') as f:
            f.write(message)
            f.flush()

    def flush(self):
        self.stream.flush()


def setup_complete_logging(log_dir, name="MART"):
    """
    Setup complete logging that captures all output

    Args:
        log_dir: Directory to save log files
        name: Logger name

    Returns:
        logger: Logger instance
    """
    # Create log directory
    os.makedirs(log_dir, exist_ok=True)

    # Create timestamped log file
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    console_log_file = os.path.join(log_dir, f"{name}_console_{timestamp}.log")

    # Setup stdout/stderr redirection
    tee_stdout = TeeLogger(console_log_file, sys.stdout)
    tee_stderr = TeeLogger(console_log_file, sys.stderr)

    sys.stdout = tee_stdout
    sys.stderr = tee_stderr

    # Create regular logger for structured logging
    logger = Logger(log_dir, name)

    return logger