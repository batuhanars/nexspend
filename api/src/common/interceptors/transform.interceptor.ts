import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  StreamableFile,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

export interface Response<T> {
  success: boolean;
  statusCode: number;
  data: T;
}

@Injectable()
export class TransformInterceptor<T> implements NestInterceptor<
  T,
  Response<T> | StreamableFile
> {
  intercept(
    context: ExecutionContext,
    next: CallHandler,
  ): Observable<Response<T> | StreamableFile> {
    const statusCode = context
      .switchToHttp()
      .getResponse<{ statusCode: number }>().statusCode;

    return next.handle().pipe(
      map((data: T | StreamableFile) => {
        if (data instanceof StreamableFile) return data;
        return {
          success: true,
          statusCode,
          data: data,
        };
      }),
    );
  }
}
