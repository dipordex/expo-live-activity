import { EventSubscription } from 'expo-modules-core';
type Voidable<T> = T | void;
export type DynamicIslandTimerType = 'circular' | 'digital';
type StopWatch = {
    id: string;
    startedAt: number | null;
    accumulated: number;
    isRunning: boolean;
    lapCount: number;
}

type Timer = {
    id?: string;
    duration?: number;
    remaining?: number;
    isRunning?: boolean;
    endsAt?: number;
}
export type LiveActivityState = {
    title: string;
    subtitle?: string;
    mode?: string;
    stopwatch?: StopWatch;
    timer?: Timer;
    showInDynamicIsland?: boolean;
};
export type NativeLiveActivityState = {
    title: string;
    subtitle?: string;
    mode?: string;
    stopwatch?: StopWatch;
    timer?: Timer;
    showInDynamicIsland?: boolean;
};
export type Padding = {
    top?: number;
    bottom?: number;
    left?: number;
    right?: number;
    vertical?: number;
    horizontal?: number;
} | number;
export type ImagePosition = 'left' | 'right' | 'leftStretch' | 'rightStretch';
export type ImageAlign = 'top' | 'center' | 'bottom';
export type ImageDimension = number | `${number}%`;
export type ImageSize = {
    width: ImageDimension;
    height: ImageDimension;
};
export type ImageContentFit = 'cover' | 'contain' | 'fill' | 'none' | 'scale-down';
export type LiveActivityConfig = {
    backgroundColor?: string;
    titleColor?: string;
    subtitleColor?: string;
    progressViewTint?: string;
    progressViewLabelColor?: string;
    deepLinkUrl?: string;
    timerType?: DynamicIslandTimerType;
    padding?: Padding;
    imagePosition?: ImagePosition;
    imageAlign?: ImageAlign;
    imageSize?: ImageSize;
    contentFit?: ImageContentFit;
    apiEndpoint?: ApiEndpoint
    accessToken?: string
};
export type ActivityTokenReceivedEvent = {
    activityID: string;
    activityName: string;
    activityPushToken: string;
};
export type ActivityPushToStartTokenReceivedEvent = {
    activityPushToStartToken: string;
};

type ApiEndpoint = {
  stopwatchEndpoints?: StopwatchEndpoints
}

type StopwatchEndpoints = {
  common: String
  lap: String
}

type ActivityState = 'active' | 'dismissed' | 'pending' | 'stale' | 'ended';
export type ActivityUpdateEvent = {
    activityID: string;
    activityName: string;
    activityState: ActivityState;
    activityAction?: string;
    stopwatchId?: string;
    timerId?: string;
    mode?: string;
};
export type LiveActivityModuleEvents = {
    onTokenReceived: (params: ActivityTokenReceivedEvent) => void;
    onPushToStartTokenReceived: (params: ActivityPushToStartTokenReceivedEvent) => void;
    onStateChange: (params: ActivityUpdateEvent) => void;
    onButtonPressed: (params: ActivityUpdateEvent) => void;
};
/**
 * @param {LiveActivityState} state The state for the live activity.
 * @param {LiveActivityConfig} config Live activity config object.
 * @returns {string} The identifier of the started activity or undefined if creating live activity failed.
 */
export declare function startActivity(state: LiveActivityState, config?: LiveActivityConfig): Voidable<string>;
/**
 * @param {string} id The identifier of the activity to stop.
 * @param {LiveActivityState} state The updated state for the live activity.
 */
export declare function stopActivity(id: string, state: LiveActivityState): any;
/**
 * @param {string} id The identifier of the activity to update.
 * @param {LiveActivityState} state The updated state for the live activity.
 */
export declare function updateActivity(id: string, state: LiveActivityState): any;
export declare function addActivityTokenListener(listener: (event: ActivityTokenReceivedEvent) => void): Voidable<EventSubscription>;
export declare function addActivityPushToStartTokenListener(listener: (event: ActivityPushToStartTokenReceivedEvent) => void): Voidable<EventSubscription>;
export declare function addActivityUpdatesListener(listener: (event: ActivityUpdateEvent) => void): Voidable<EventSubscription>;
export declare function addActivityActionListener(listener: (event: ActivityUpdateEvent) => void): Voidable<EventSubscription>;
export { };
//# sourceMappingURL=index.d.ts.map