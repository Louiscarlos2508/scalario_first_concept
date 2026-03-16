import { Injectable, NotFoundException, OnModuleInit } from '@nestjs/common';
import * as fs from 'fs';
import * as path from 'path';

@Injectable()
export class SduiService implements OnModuleInit {
  private readonly layouts = new Map<string, object>();

  onModuleInit(): void {
    const layoutsDir = path.join(__dirname, 'layouts');
    if (!fs.existsSync(layoutsDir)) return;

    const files = fs.readdirSync(layoutsDir).filter((f) => f.endsWith('.json'));
    for (const file of files) {
      // filename format: {business_type}.{screen}.json  →  key: {business_type}.{screen}
      const key = file.replace(/\.json$/, '');
      const content = fs.readFileSync(path.join(layoutsDir, file), 'utf-8');
      this.layouts.set(key, JSON.parse(content));
    }
  }

  getLayout(businessType: string, screen: string): object {
    const key = `${businessType}.${screen}`;
    const layout = this.layouts.get(key);
    if (!layout) {
      throw new NotFoundException('Layout introuvable pour ce type de commerce');
    }
    return layout;
  }
}
