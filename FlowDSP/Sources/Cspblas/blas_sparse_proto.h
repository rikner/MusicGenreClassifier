#ifndef BLAS_SPARSE_PROTO_H
#define BLAS_SPARSE_PROTO_H

#ifdef __cplusplus
extern "C" {  // only need to export C interface if
              // used by C++ source code
#endif

typedef int blas_sparse_matrix;

/* Level 1 Computational Routines */

void sparse_usdot_float( int nz, const float *x, const int *indx, const float *y, int incy, float *r, enum blas_base_type index_base );
void sparse_usdot_double( int nz, const double *x, const int *indx, const double *y, int incy, double *r, enum blas_base_type index_base );

void sparse_usaxpy_float( int nz, float alpha, const float *x, const int *indx, float *y, int incy, enum blas_base_type index_base );
void sparse_usaxpy_double( int nz, double alpha, const double *x, const int *indx, double *y, int incy, enum blas_base_type index_base );

void sparse_usga_float( int nz, const float *y, int incy, float *x, const int *indx,enum blas_base_type index_base );
void sparse_usga_double( int nz, const double *y, int incy, double *x, const int *indx,enum blas_base_type index_base );

void sparse_usgz_float( int nz, float *y, int incy, float *x, const int *indx,enum blas_base_type index_base );
void sparse_usgz_double( int nz, double *y, int incy, double *x, const int *indx,enum blas_base_type index_base );

void sparse_ussc_float( int nz, const float *x, float *y, int incy, const int *indx,enum blas_base_type index_base );
void sparse_ussc_double( int nz, const double *x, double *y, int incy, const int *indx,enum blas_base_type index_base );

/* Level 2 Computational Routines */

int sparse_usmv_float( enum blas_trans_type transa, float alpha, blas_sparse_matrix A, const float *x, int incx, float *y, int incy );
int sparse_usmv_double( enum blas_trans_type transa, double alpha, blas_sparse_matrix A, const double *x, int incx, double *y, int incy );

int sparse_ussv_float( enum blas_trans_type transt, float alpha, blas_sparse_matrix T, float *x, int incx );
int sparse_ussv_double( enum blas_trans_type transt, double alpha, blas_sparse_matrix T, double *x, int incx );

/* Level 3 Computational Routines */

int sparse_usmm_float( enum blas_order_type order, enum blas_trans_type transa, int nrhs, float alpha, blas_sparse_matrix A, const float *b, int ldb, float *c, int ldc );
int sparse_usmm_double( enum blas_order_type order, enum blas_trans_type transa, int nrhs, double alpha, blas_sparse_matrix A, const double *b, int ldb, double *c, int ldc );

int sparse_ussm_float( enum blas_order_type order, enum blas_trans_type transt,int nrhs, float alpha, int t, float *b, int ldb );
int sparse_ussm_double( enum blas_order_type order, enum blas_trans_type transt,int nrhs, double alpha, int t, double *b, int ldb );
 /* Handle Management Routines */
 /* Creation Routines */

blas_sparse_matrix sparse_uscr_begin_float( int m, int n );
blas_sparse_matrix sparse_uscr_begin_double( int m, int n );


blas_sparse_matrix sparse_uscr_block_begin_float( int Mb, int Nb, int k, int l );
blas_sparse_matrix sparse_uscr_block_begin_double( int Mb, int Nb, int k, int l );

blas_sparse_matrix sparse_uscr_variable_block_begin_float( int Mb, int Nb, const int *k, const int *l );
blas_sparse_matrix sparse_uscr_variable_block_begin_double( int Mb, int Nb, const int *k, const int *l );

 /* Insertion Routines */

int sparse_get_entry_float( blas_sparse_matrix A, int i, int j, float* result, int* colIndex );

int sparse_uscr_insert_entry_float( blas_sparse_matrix A, float val, int i, int j );
int sparse_uscr_insert_entry_double( blas_sparse_matrix A, double val, int i, int j );

int sparse_uscr_insert_entries_float( blas_sparse_matrix A, int nz, const float *val,const int *indx, const int *jndx );
int sparse_uscr_insert_entries_double( blas_sparse_matrix A, int nz, const double *val,const int *indx, const int *jndx );

int sparse_uscr_insert_col_float( blas_sparse_matrix A, int j, int nz, const float *val, const int *indx );
int sparse_uscr_insert_col_double( blas_sparse_matrix A, int j, int nz, const double *val, const int *indx );

int sparse_uscr_insert_row_float( blas_sparse_matrix A, int i, int nz, const float *val, const int *indx );
int sparse_uscr_insert_row_double( blas_sparse_matrix A, int i, int nz, const double *val, const int *indx );

int sparse_uscr_insert_clique_float( blas_sparse_matrix A, const int k, const int l, const float *val, const int row_stride, const int col_stride, const int *indx, const int *jndx );
int sparse_uscr_insert_clique_double( blas_sparse_matrix A, const int k, const int l, const double *val, const int row_stride, const int col_stride, const int *indx, const int *jndx );

int sparse_uscr_insert_block_float( blas_sparse_matrix A, const float *val, int row_stride, int col_stride, int i, int j );
int sparse_uscr_insert_block_double( blas_sparse_matrix A, const double *val, int row_stride, int col_stride, int i, int j );

/* Completion of Construction Routines */

int sparse_uscr_end_float( blas_sparse_matrix A );
int sparse_uscr_end_double( blas_sparse_matrix A );

/* Matrix Property Routines */

int BLAS_usgp( blas_sparse_matrix A, int pname );
int BLAS_ussp( blas_sparse_matrix A, int pname );

/* Destruction Routine */

int BLAS_usds( blas_sparse_matrix A );

#ifdef __cplusplus
}
#endif

#endif
/* BLAS_SPARSE_PROTO_H */
