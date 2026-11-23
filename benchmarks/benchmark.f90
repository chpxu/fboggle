! -----------------------------------------------------------------------------
! Benchmark
! -----------------------------------------------------------------------------

!!*** benchmarks/benchmark.f90 *
!!  NAME
!!   benchmark_params
!!  PURPOSE
!!   Generates random test cases for fboggle
!!  USES
!!  AUTHOR
!!   chpxu
!!  CREATION DATE
!!   23/11/2026
!!  MODIFICATION HISTORY
!***

module benchmark_params

   use, intrinsic :: iso_fortran_env, dp => int64
   implicit none 

   integer(dp), parameter :: GRID_SIZES(9) = [4, 8, 16, 32, &
                                           64, 128, 256, 512, 1024]
   integer(dp), parameter :: SEED_VALUE = 20261123                       
   integer(dp), parameter :: ALPHABET_SIZE = 26
   character(len=ALPHABET_SIZE), parameter :: ALPHABET = 'abcdefghijklmnopqrstuvwxyz'
   integer(dp), parameter :: LETTER_WEIGHTS(ALPHABET_SIZE) = [8, 2, 3, 4, 12, 2, 2, 6, 7, 1, &
                                                          1, 4, 2, 7, 8, 2, 1, 6, 6, 9, 3, 1, 2, 1, 2, 1]

   character(len=256), parameter :: benchmark_dir = "./benchmarks"
end module benchmark_params
program BoggleBenchmark
   use benchmark_params
   implicit none

   character(len=256)  :: filename
   character, allocatable :: row_letters(:)
   integer, allocatable :: seeds(:)
   integer :: seed_length
   integer :: i, idx, grid_size, row_idx, column_idx 
   integer :: iounit, ios

   call random_seed(size=seed_length)
   seeds = SEED_VALUE + [(26*i, i=1, seed_length)]
   call random_seed(put=seeds)
   do idx = 1, size(GRID_SIZES)
      grid_size = GRID_SIZES(idx)
      ! Write params_"grid_size".txt
      write (filename, '(a,"/params_",i0,"x",i0,".txt")') &
         trim(benchmark_dir), grid_size, grid_size

      open (newunit=iounit, file=filename, status='replace', action='write', iostat=ios)
      if (ios /= 0) then
         print '(2A)', 'Error writing params file: ', trim(filename)
         stop
      end if ! ios /=0
      write (iounit, '(I0)') grid_size
      allocate (row_letters(grid_size))
      do row_idx = 1, grid_size
         do column_idx = 1, grid_size
            row_letters(column_idx) = random_letter()
         end do ! random_letter column
         write (iounit, '(*(A,:,1x))') row_letters
      end do ! row
      deallocate (row_letters)
      close (iounit)
   end do ! idx = 1, size(GRID_SIZES)

contains
   function random_letter() result(letter)
      use, intrinsic :: iso_fortran_env, dp => real64
      use benchmark_params, only: ALPHABET, ALPHABET_SIZE, LETTER_WEIGHTS
      implicit none

      character :: letter
      real(dp) :: random_real
      integer :: target_weight, cumsum, letter_idx

      call random_number(random_real)
      target_weight = int(random_real*sum(LETTER_WEIGHTS))
      cumsum = 0
      do letter_idx = 1, ALPHABET_SIZE
         cumsum = cumsum + LETTER_WEIGHTS(letter_idx)
         if (target_weight<=cumsum) then
            letter = ALPHABET(letter_idx:letter_idx)
            return
         end if
      end do ! letter_idx
   end function random_letter
end program BoggleBenchmark
