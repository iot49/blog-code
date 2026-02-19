import fs from 'fs';
import yaml from 'js-yaml';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const accessListPath = path.join(__dirname, 'access-list.yaml');

try {
  const fileContents = fs.readFileSync(accessListPath, 'utf8');
  const data = yaml.load(fileContents);
  process.stdout.write(JSON.stringify(data));
} catch (e) {
  console.error(e);
  process.exit(1);
}
