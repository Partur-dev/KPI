export const handleFatalError = (message) => (err) => {
  console.error(message, err);
  process.exit(1);
};
