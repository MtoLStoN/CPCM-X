module sdm 

   contains

      !> Example implementation to calculate surface area for a molecule input
      subroutine calculate_cds(species, symbols, coord, probe, solvent, path, default)
      use mctc_env, only : wp
      use numsa, only : surface_integrator, new_surface_integrator, get_vdw_rad_bondi, grid_size
      use smd, only: init_smd, smd_param, calc_surft, smd_surft, calc_cds, ascii_cds
      use globals, only: dG_disp, BtoA
      !> Unique chemical species in the input structure, shape: [nat]
      integer, intent(in) :: species(:)
      !> Element symbol for each chemical species, shape: [nsp]
      character(len=*), intent(in) :: symbols(:)
      !> Cartesian coordinates in Bohr, shape: [3, nat]
      real(wp), intent(in) :: coord(:, :)
      real(wp), allocatable :: coord_rev(:,:)
      !> Probe radius for surface area integration in Bohr
      real(wp), intent(in) :: probe
      !> Accessible surface area in Bohr², shape: [nat]
      real(wp),allocatable :: surface(:)
      !> Derivative of surface area w.r.t. atomic displacements, shape: [3, nat, nat]
      real(wp),allocatable :: dsdr(:, :, :)
      !> Using default SMD Parameters?
      logical, intent(in) :: default
      !>Laufen
      integer :: i, j
      !> Read Env
      integer :: dummy1,io_error
      !> Parameter Path and Solvent Name
      character(len=*) :: path, solvent
      logical :: ex
      real(wp),allocatable :: cds(:)
      real(wp) :: cds_sm

      type(surface_integrator) :: sasa
      type(smd_param) :: param
      type(smd_surft) :: surft
      real(wp), allocatable :: rad(:)

      allocate (surface(size(species)))
      allocate (dsdr(3,size(species),size(species)))
      allocate(coord_rev(3,size(species)))



      if (.NOT. default) then
         select case (solvent)
            case ('h2o','water')
               INQUIRE(file=path//"smd_h2o",exist=ex)
            case default
               INQUIRE(file=path//"smd_ot",exist=ex)
         end select
         if (.NOT. ex) then
            write(*,*) "Parameter file for SMD model does not exists in the specified path."
            write(*,*) "Path: "//path
            write(*,*) "You can skip this check (using default parameters) by using the default_smd keyword!"
            stop
         end if
      end if
      do i=1,3
         do j=1,size(species)
            coord_rev(i,j)=coord(j,i)*(1/BtoA)
         end do
      end do
      
      rad = get_vdw_rad_bondi(symbols)
      rad = rad+0.4
      call new_surface_integrator(sasa, species, rad, probe, grid_size(8))
      call sasa%get_surface(species, coord_rev, surface, dsdr)
      if (default) then
         Call init_smd(param,solvent)
      else
         Call init_smd(param,solvent,path)
      end if
      Call calc_surft(coord_rev,species,symbols,param,surft)
      Call calc_cds(surft,surface,cds,cds_sm)
      dG_disp= (sum(cds)+cds_sm)/1000
end subroutine calculate_cds
   



end module sdm