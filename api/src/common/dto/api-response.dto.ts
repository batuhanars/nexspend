export class ApiResponseDto<T> {
  success: boolean;
  data?: T;
  message?: string;
  statusCode: number;

  static ok<T>(data: T, message?: string): ApiResponseDto<T> {
    return { success: true, data, message, statusCode: 200 };
  }

  static created<T>(data: T): ApiResponseDto<T> {
    return { success: true, data, statusCode: 201 };
  }
}

export class PaginationDto {
  page?: number = 1;
  limit?: number = 20;
}

export class PaginatedResponseDto<T> {
  data: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}
