import { Injectable } from '@nestjs/common';
import { createMachine, AnyStateMachine } from 'xstate';
import type { WorkflowFsmDef } from './workflow-fsm.types';

@Injectable()
export class FsmBuilder {
  build(def: WorkflowFsmDef): AnyStateMachine {
    const machineConfig: Record<string, unknown> = {
      id: def.id,
      initial: def.initial,
      states: {} as Record<string, unknown>,
    };
    const outStates: Record<string, unknown> = {};

    for (const [name, s] of Object.entries(def.states)) {
      const nodeConfig: Record<string, unknown> = {};
      if (s.type === 'final') {
        nodeConfig.type = 'final';
      }
      if (s.on) {
        const onMap: Record<string, unknown> = {};
        for (const [event, target] of Object.entries(s.on)) {
          onMap[event] = typeof target === 'string' ? target : target.target;
        }
        nodeConfig.on = onMap;
      }
      if (s.meta) {
        nodeConfig.meta = s.meta;
      }
      outStates[name] = nodeConfig;
    }

    machineConfig.states = outStates;
    return createMachine(machineConfig as any);
  }
}
