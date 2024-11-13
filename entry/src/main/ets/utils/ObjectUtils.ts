export class ObjectUtils {
  /**
   *对象合并
   * @param target 目标对象
   * @param source 源对象
   * @return 合并后的对象
   **/
  static assign(target: Object, source?: Object): Object {
    return Object.assign(target, source);
  }
}